import dotenv from "dotenv";

dotenv.config();

export const env = {
  port: Number(process.env.PORT || 5001),
  nodeEnv: process.env.NODE_ENV || "development",
  // Allow common local Vite ports for development
  allowedOrigins: [
    process.env.FRONTEND_URL || "http://localhost:3000",
    "http://localhost:3001",
    "http://localhost:5173",
    "http://localhost:5174",
    "http://localhost:5175",
    "http://localhost:5176"
  ],
  supabaseUrl: process.env.SUPABASE_URL || "",
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY || "",
  supabaseServiceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY || "",
  supabaseJwtSecret: process.env.SUPABASE_JWT_SECRET || "default_secret_change_me",
  databaseUrl: process.env.DATABASE_URL || "",
  /** Email address for the platform super admin who can view all schools */
  superAdminEmail: process.env.SUPER_ADMIN_EMAIL || "admin@educontrol.com"
};
