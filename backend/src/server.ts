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
    ? { maxAge: 31_536_000, includeSubDomains: true, preload: true }
    : false,
  referrerPolicy: { policy: "no-referrer" },
}));
app.use(cors({
  origin: (origin, callback) => {
    if (env.isOriginAllowed(origin)) {
      callback(null, true);
    } else {
      callback(new Error("Not allowed by CORS"));
    }
  },
  credentials: true
}));
app.use(express.json({ limit: "5mb" }));
app.use(express.urlencoded({ limit: "5mb", extended: true }));
app.use(morgan("dev"));

app.use("/api", apiLimiter, routes);

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
  // eslint-disable-next-line no-console
  console.log(`Server running on http://localhost:${env.port}`);
  console.log(`WebSocket ready on ws://localhost:${env.port}`);

  // Start automatic overdue invoice checker
  startOverdueChecker();
});
