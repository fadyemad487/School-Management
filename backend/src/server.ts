import cors from "cors";
import express from "express";
import helmet from "helmet";
import morgan from "morgan";
import { createServer } from "http";
import { env } from "./config/env";
import { errorHandler } from "./middlewares/errorHandler";
import { apiLimiter } from "./middlewares/rateLimit";
import { initWebSocket } from "./config/websocket";
import { startOverdueChecker } from "./cron/checkOverdueInvoices";
import routes from "./routes";
import { logger } from "./utils/logger";

const app = express();
const httpServer = createServer(app);

// Railway and other reverse proxies terminate TLS before forwarding requests.
// Trust exactly one proxy so req.ip remains reliable for rate limiting.
app.set("trust proxy", 1);
app.disable("x-powered-by");

// Initialize WebSocket with school-based room isolation
initWebSocket(httpServer);

app.use(helmet({
  hsts: env.nodeEnv === "production"
    ? { maxAge: 63072000, includeSubDomains: true, preload: true }
    : false,
  referrerPolicy: { policy: "strict-origin-when-cross-origin" },
  frameguard: { action: "deny" },
  noSniff: true,
  xssFilter: true,
}));
app.use(cors({
  origin: (origin, callback) => {
    if (env.isOriginAllowed(origin)) {
      callback(null, true);
    } else {
      logger.security("CORS origin blocked", { origin, ip: "unknown" });
      callback(new Error("Not allowed by CORS"));
    }
  },
  credentials: true,
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization", "X-XSRF-TOKEN", "X-CSRF-TOKEN"],
  exposedHeaders: ["X-RateLimit-Limit", "X-RateLimit-Remaining", "X-RateLimit-Reset"],
  maxAge: 86400, // 24 hours
}));

app.use(express.json({
  limit: "1mb",
}));
app.use(express.urlencoded({ limit: "1mb", extended: true }));

if (env.nodeEnv === "development") {
  app.use(morgan("dev"));
}

app.use("/api", (_req, res, next) => {
  res.setHeader("Cache-Control", "no-store, private");
  next();
}, apiLimiter, routes);

app.get("/", (_req, res) => {
  res.json({ 
    message: "EduControl API is running", 
    version: "2.0.0",
    docs: "/api/health",
    features: ["multi-tenant", "websocket", "real-time"]
  });
});

// Global error handler — must be last middleware
app.use(errorHandler);

httpServer.listen(env.port, () => {
  logger.info("Server started successfully", {
    port: env.port,
    environment: env.nodeEnv,
    websocket: "enabled",
    security: "enhanced",
  });

  if (env.nodeEnv === "development") {
    console.log(`\n🚀 Server running on http://localhost:${env.port}`);
    console.log(`🔌 WebSocket ready on ws://localhost:${env.port}`);
    console.log(`🔒 Security: Enhanced mode with 7 protection layers\n`);
  }

  // Start automatic overdue invoice checker
  startOverdueChecker();
});
