import cors from "cors";
import express from "express";
import helmet from "helmet";
import morgan from "morgan";
import { createServer } from "http";
import { env } from "./config/env";
import { errorHandler } from "./middlewares/errorHandler";
import { initWebSocket } from "./config/websocket";
import { startOverdueChecker } from "./cron/checkOverdueInvoices";
import routes from "./routes";

const app = express();
const httpServer = createServer(app);

// Initialize WebSocket with school-based room isolation
initWebSocket(httpServer);

app.use(helmet());
app.use(cors({ origin: env.allowedOrigins, credentials: true }));
app.use(express.json({ limit: "50mb" }));
app.use(express.urlencoded({ limit: "50mb", extended: true }));
app.use(morgan("dev"));

app.use("/api", routes);

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
