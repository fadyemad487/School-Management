import dotenv from "dotenv";

dotenv.config();

const nodeEnv = process.env.NODE_ENV || "development";
const jwtSecret = process.env.SUPABASE_JWT_SECRET || (nodeEnv === "production" ? "" : "dev_fallback_secret_change_me");
const configuredFrontendOrigins = (process.env.FRONTEND_URL || "")
  .split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);
const localOrigins = [
  "http://localhost",
  "http://localhost:80",
  "http://localhost:3000",
  "http://localhost:3001",
  "http://localhost:5001",
  "http://localhost:5173",
  "http://localhost:5174",
  "http://localhost:5175",
  "http://localhost:5176",
  "http://127.0.0.1",
  "http://127.0.0.1:80",
  "http://127.0.0.1:3000",
  "http://127.0.0.1:5001",
];
const productionOrigins = [
  "https://school-management487.vercel.app",
  ...configuredFrontendOrigins,
];

if (nodeEnv === "production" && (!jwtSecret || jwtSecret === "dev_fallback_secret_change_me" || jwtSecret === "default_secret_change_me")) {
  throw new Error("[SECURITY CRITICAL] SUPABASE_JWT_SECRET environment variable is missing or set to insecure default in production.");
}

export const env = {
  port: Number(process.env.PORT || 5001),
  nodeEnv,
  // Production must only accept the deployed frontend and explicitly configured domains.
  // Do not use broad "*.vercel.app" or "*.netlify.app" matches here.
  isOriginAllowed: (origin?: string): boolean => {
    if (!origin) return true;
    const cleanOrigin = origin.replace(/\/$/, "");
    const allowedOrigins = nodeEnv === "production"
      ? productionOrigins
      : [...localOrigins, ...productionOrigins];
    if (allowedOrigins.includes(cleanOrigin)) {
      return true;
    }
    if (
      /^https:\/\/school-management487(-[a-z0-9-]+)?\.vercel\.app$/.test(cleanOrigin) ||
      /^https:\/\/school-management(-[a-z0-9-]+)?-fadyemad487\.vercel\.app$/.test(cleanOrigin)
    ) {
      return true;
    }
    return false;
  },
  supabaseUrl: process.env.SUPABASE_URL || "",
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY || "",
  supabaseServiceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY || "",
  supabaseJwtSecret: jwtSecret,
  databaseUrl: process.env.DATABASE_URL || "",
  /** Email address for the platform super admin who can view all schools */
  superAdminEmail: process.env.SUPER_ADMIN_EMAIL || "admin@educontrol.com"
};
