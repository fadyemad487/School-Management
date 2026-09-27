import type { Session } from "@supabase/supabase-js";

const rememberedSessionKey = "edu_remembered_session";
const rememberPreferenceKey = "edu_remember_me";

type StoredSession = Pick<Session, "access_token" | "refresh_token">;

export function persistRememberedSession(session: Session | StoredSession, remember: boolean): void {
  if (typeof window === "undefined") return;

  if (!remember) {
    clearRememberedSession();
    return;
  }

  localStorage.setItem(rememberPreferenceKey, "true");
  localStorage.setItem(
    rememberedSessionKey,
    JSON.stringify({
      access_token: session.access_token,
      refresh_token: session.refresh_token,
    }),
  );
}

export function getRememberedSession(): StoredSession | null {
  if (typeof window === "undefined" || localStorage.getItem(rememberPreferenceKey) !== "true") {
    return null;
  }

  try {
    const stored = JSON.parse(localStorage.getItem(rememberedSessionKey) || "") as StoredSession;
    return stored.access_token && stored.refresh_token ? stored : null;
  } catch {
    clearRememberedSession();
    return null;
  }
}

export function syncRememberedSession(session: Session | null): void {
  if (session && typeof window !== "undefined" && localStorage.getItem(rememberPreferenceKey) === "true") {
    persistRememberedSession(session, true);
  }
}

export function clearRememberedSession(): void {
  if (typeof window === "undefined") return;
  localStorage.removeItem(rememberPreferenceKey);
  localStorage.removeItem(rememberedSessionKey);
}
