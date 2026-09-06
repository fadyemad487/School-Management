import dotenv from "dotenv";

dotenv.config();

const nodeEnv = process.env.NODE_ENV || "development";
const jwtSecret = process.env.SUPABASE_JWT_SECRET || (nodeEnv === "production" ? "" : "dev_fallback_secret_change_me");

if (nodeEnv === "production" && (!jwtSecret || jwtSecret === "dev_fallback_secret_change_me" || jwtSecret === "default_secret_change_me")) {
  throw new Error("[SECURITY CRITICAL] SUPABASE_JWT_SECRET environment variable is missing or set to insecure default in production.");
}

export const env = {
  port: Number(process.env.PORT || 5001),
  nodeEnv,
  // Dynamic origin validation supporting Localhost, Vercel, Netlify, and custom FRONTEND_URL
  isOriginAllowed: (origin?: string): boolean => {
    if (!origin) return true;
    const explicitlyAllowed = [
      "http://localhost:3000",
      "http://localhost:3001",
      "http://localhost:5173",
      "http://localhost:5174",
      "http://localhost:5175",
      "http://localhost:5176",
      ...(process.env.FRONTEND_URL ? process.env.FRONTEND_URL.split(",").map(u => u.trim()) : [])
    ];
    if (explicitlyAllowed.includes(origin)) return true;
    try {
      const parsed = new URL(origin);
      if (parsed.hostname.endsWith(".vercel.app") || parsed.hostname.endsWith(".netlify.app")) {
        return true;
      }
    } catch (_) {}
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
