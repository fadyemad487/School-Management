import axios from "axios";
import { getCurrentSession, supabase } from "./supabase";

export const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || "http://localhost:5001/api"
});

// Attach the current Supabase auth token to API requests.
api.interceptors.request.use(async (config) => {
  const session = await getCurrentSession();
  const token = session?.access_token;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }

  return config;
});

let isRefreshing = false;
let failedQueue: Array<{ resolve: (value?: unknown) => void; reject: (reason?: unknown) => void }> = [];

const processQueue = (error: any = null) => {
  failedQueue.forEach((prom) => {
    if (error) {
      prom.reject(error);
    } else {
      prom.resolve();
    }
  });
  failedQueue = [];
};

// Handle token expiration seamlessly: attempt refresh session before signing out.
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    if (axios.isAxiosError(error) && error.response?.status === 401 && originalRequest && !originalRequest._retry) {
      if (isRefreshing) {
        return new Promise((resolve, reject) => {
          failedQueue.push({ resolve, reject });
        })
          .then(() => {
            return api(originalRequest);
          })
          .catch((err) => {
            return Promise.reject(err);
          });
      }

      originalRequest._retry = true;
      isRefreshing = true;

      try {
        const { data, error: refreshErr } = await supabase.auth.refreshSession();
        if (refreshErr || !data.session) {
          processQueue(refreshErr || new Error("Session refresh failed"));
          await supabase.auth.signOut();
          return Promise.reject(error);
        }

        processQueue(null);
        originalRequest.headers.Authorization = `Bearer ${data.session.access_token}`;
        return api(originalRequest);
      } catch (err) {
        processQueue(err);
        await supabase.auth.signOut();
        return Promise.reject(err);
      } finally {
        isRefreshing = false;
      }
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
