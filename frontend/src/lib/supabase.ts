import { createClient, processLock } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || "";
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || "";

export const PASSWORD_RECOVERY_SESSION_KEY = "edu_password_recovery";

export function hasVerifiedPasswordRecovery() {
  if (typeof window === "undefined") return false;

  try {
    return window.sessionStorage.getItem(PASSWORD_RECOVERY_SESSION_KEY) === "1";
  } catch {
    return false;
  }
}

export function hasPasswordRecoveryContext() {
  if (typeof window === "undefined") return false;

  try {
    if (hasVerifiedPasswordRecovery()) return true;
    if (window.location.pathname !== "/update-password") return false;

    const query = new URLSearchParams(window.location.search);
    const hash = new URLSearchParams(window.location.hash.slice(1));
    return query.has("code") || query.get("type") === "recovery" || hash.get("type") === "recovery";
  } catch {
    return false;
  }
}

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
    // process-local lock protects concurrent React/API reads
    lock: processLock,
    lockAcquireTimeout: 10_000,
    storage: typeof window === "undefined" ? undefined : window.localStorage,
  },
});

/** Verify, rather than trusting the client-editable sessionStorage marker, that
 * this session's signed Supabase token was actually issued for password recovery. */
export async function isVerifiedPasswordRecoverySession(session: {
  access_token: string;
  user: { id: string };
} | null | undefined) {
  if (!session?.access_token || !session.user?.id) return false;

  try {
    const { data, error } = await supabase.auth.getClaims(session.access_token);
    const claims = data?.claims;
    if (
      error || !claims || claims.sub !== session.user.id || claims.role !== "authenticated" ||
      !(claims.aud === "authenticated" || (Array.isArray(claims.aud) && claims.aud.includes("authenticated"))) ||
      !Array.isArray(claims.amr)
    ) return false;

    // AMR records the methods used in the session. A refresh can add a
    // token_refresh entry, so reject any session that still carries recovery.
    return claims.amr.some((item) => Boolean(item) && typeof item === "object" && item.method === "recovery");
  } catch {
    return false;
  }
}

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
