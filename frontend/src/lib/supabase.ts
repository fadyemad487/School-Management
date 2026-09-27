import { createClient, processLock } from "@supabase/supabase-js";

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

/**
 * Keep the authenticated session only for the lifetime of the current browser
 * tab.  Supabase defaults to localStorage, which survives closing the browser
 * and is not appropriate for an administrative school dashboard on shared
 * devices.  sessionStorage still permits a normal page refresh in this tab.
 */
export const supabase = createClient(safeUrl, safeKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    // sessionStorage is isolated per browser tab. A process-local lock therefore
    // protects concurrent React/API reads without competing for a browser-wide
    // Navigator Lock held by another Supabase operation.
    lock: processLock,
    lockAcquireTimeout: 10_000,
    storage: typeof window === "undefined" ? undefined : window.sessionStorage,
  },
});

let sessionRequest: Promise<Awaited<ReturnType<typeof supabase.auth.getSession>>["data"]["session"]> | null = null;

/**
 * Serializes simultaneous session reads. Supabase uses the browser LockManager
 * internally; a single shared read prevents competing React effects and API
 * requests from trying to acquire the same auth lock at once.
 */
export function getCurrentSession() {
  if (!sessionRequest) {
    sessionRequest = supabase.auth
      .getSession()
      .then(({ data }) => data.session)
      .finally(() => {
        sessionRequest = null;
      });
  }

  return sessionRequest;
}
