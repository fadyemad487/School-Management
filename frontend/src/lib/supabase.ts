import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || "";
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || "";

export const isSupabaseConfigured = Boolean(
  supabaseUrl && 
  supabaseAnonKey && 
  supabaseUrl !== "your_supabase_url" &&
  supabaseUrl.startsWith("https://")
);

// Avoid runtime crash when env vars are missing during first run.
const safeUrl = isSupabaseConfigured ? supabaseUrl : "https://placeholder.supabase.co";
const safeKey = isSupabaseConfigured ? supabaseAnonKey : "placeholder-anon-key";

export const supabase = createClient(safeUrl, safeKey);
