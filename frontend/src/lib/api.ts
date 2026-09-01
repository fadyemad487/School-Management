import axios from "axios";
import { supabase } from "./supabase";

export const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || "http://localhost:5001/api"
});

// Attach Supabase auth token and disable browser caching to keep data 100% fresh
api.interceptors.request.use(async (config) => {
  const { data } = await supabase.auth.getSession();
  const token = data.session?.access_token;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }

  // Prevent browser caching on localhost during development/navigation
  config.headers["Cache-Control"] = "no-cache, no-store, must-revalidate";
  config.headers["Pragma"] = "no-cache";
  config.headers["Expires"] = "0";

  return config;
});

// A rejected/expired token must not leave a stale authenticated UI on screen.
// The provider observes the SIGNED_OUT event and returns the user to login.
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (axios.isAxiosError(error) && error.response?.status === 401) {
      await supabase.auth.signOut();
    }
    return Promise.reject(error);
  }
);

/**
 * Structured error returned by the backend.
 */
export interface ApiError {
  success: false;
  code: string;
  message: string;
  field?: string;
  errors?: Array<{ field: string; message: string }>;
}

/**
 * Extract a structured error from an Axios error response.
 */
export function extractApiError(error: unknown): ApiError {
  if (axios.isAxiosError(error) && error.response?.data) {
    return error.response.data as ApiError;
  }
  return {
    success: false,
    code: "UNKNOWN",
    message: error instanceof Error ? error.message : "An unexpected error occurred."
  };
}
