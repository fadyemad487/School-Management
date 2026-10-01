/**
 * CSRF Protection Middleware
 *
 * Protects against Cross-Site Request Forgery attacks by:
 * 1. Generating unique tokens per session
 * 2. Validating tokens on state-changing operations
 * 3. Using double-submit cookie pattern
 * 4. SameSite cookie attributes
 */

import type { NextFunction, Request, Response } from "express";
import crypto from "crypto";
import { logger } from "../utils/logger";

// In-memory token store (use Redis in production for scaling)
const tokenStore = new Map<string, { token: string; expiresAt: number }>();

// Token expiration time (15 minutes)
const TOKEN_EXPIRY = 15 * 60 * 1000;

// Clean up expired tokens every 5 minutes
setInterval(() => {
  const now = Date.now();
  for (const [sessionId, data] of tokenStore.entries()) {
    if (data.expiresAt <= now) {
      tokenStore.delete(sessionId);
    }
  }
}, 5 * 60 * 1000);

/**
 * Generate a cryptographically secure CSRF token
 */
function generateToken(): string {
  return crypto.randomBytes(32).toString("hex");
}

/**
 * Get session ID from request (from user ID or create temporary)
 */
function getSessionId(req: Request): string {
  return req.user?.id || `temp_${req.ip}`;
}

/**
 * Middleware to generate and attach CSRF token
 * Add this to routes that render forms or need CSRF protection
 */
export function generateCsrfToken(req: Request, res: Response, next: NextFunction): void {
  const sessionId = getSessionId(req);

  // Check if token already exists and is valid
  const existing = tokenStore.get(sessionId);
  if (existing && existing.expiresAt > Date.now()) {
    res.locals.csrfToken = existing.token;
    return next();
  }

  // Generate new token
  const token = generateToken();
  const expiresAt = Date.now() + TOKEN_EXPIRY;

  tokenStore.set(sessionId, { token, expiresAt });
  res.locals.csrfToken = token;

  // Set token in cookie (httpOnly, secure, sameSite)
  res.cookie("XSRF-TOKEN", token, {
    httpOnly: false, // Must be readable by JavaScript for axios to send it
    secure: process.env.NODE_ENV === "production",
    sameSite: "strict",
    maxAge: TOKEN_EXPIRY,
  });

  next();
}

/**
 * Middleware to validate CSRF token on state-changing requests
 * Apply this to POST, PUT, PATCH, DELETE routes
 */
export function validateCsrfToken(req: Request, res: Response, next: NextFunction): void {
  // Skip CSRF validation for GET, HEAD, OPTIONS (safe methods)
  if (["GET", "HEAD", "OPTIONS"].includes(req.method)) {
    return next();
  }

  // Skip CSRF for API endpoints using Bearer token auth (mobile apps)
  // Mobile apps use JWT tokens which are immune to CSRF
  const authHeader = req.headers.authorization;
  if (authHeader?.startsWith("Bearer ")) {
    return next();
  }

  const sessionId = getSessionId(req);
  const storedData = tokenStore.get(sessionId);

  // Check if token exists in store
  if (!storedData) {
    logger.security("CSRF validation failed: No token in store", {
      sessionId,
      method: req.method,
      path: req.path,
      ip: req.ip,
    });
    res.status(403).json({
      success: false,
      code: "CSRF_TOKEN_MISSING",
      message: "CSRF token is missing. Please refresh the page and try again.",
    });
    return;
  }

  // Check if token is expired
  if (storedData.expiresAt <= Date.now()) {
    tokenStore.delete(sessionId);
    logger.security("CSRF validation failed: Token expired", {
      sessionId,
      method: req.method,
      path: req.path,
      ip: req.ip,
    });
    res.status(403).json({
      success: false,
      code: "CSRF_TOKEN_EXPIRED",
      message: "CSRF token has expired. Please refresh the page and try again.",
    });
    return;
  }

  // Get token from header (axios sends it automatically as X-XSRF-TOKEN)
  const tokenFromHeader = req.headers["x-xsrf-token"] || req.headers["x-csrf-token"];

  // Get token from body (fallback)
  const tokenFromBody = (req.body as any)?._csrf;

  const clientToken = tokenFromHeader || tokenFromBody;

  // Validate token
  if (!clientToken || clientToken !== storedData.token) {
    logger.security("CSRF validation failed: Invalid token", {
      sessionId,
      method: req.method,
      path: req.path,
      ip: req.ip,
      hasHeaderToken: !!tokenFromHeader,
      hasBodyToken: !!tokenFromBody,
    });
    res.status(403).json({
      success: false,
      code: "CSRF_TOKEN_INVALID",
      message: "CSRF token is invalid. Please refresh the page and try again.",
    });
    return;
  }

  // Token is valid - allow request
  next();
}

/**
 * Middleware to clear CSRF token on logout
 */
export function clearCsrfToken(req: Request, res: Response, next: NextFunction): void {
  const sessionId = getSessionId(req);
  tokenStore.delete(sessionId);
  res.clearCookie("XSRF-TOKEN");
  next();
}

/**
 * Get CSRF token for current session (for API response)
 */
export function getCsrfToken(req: Request): string | null {
  const sessionId = getSessionId(req);
  const data = tokenStore.get(sessionId);
  return data?.token || null;
}
