/**
 * Advanced Security Headers Middleware
 *
 * Implements comprehensive security headers including:
 * - Content Security Policy (CSP)
 * - Strict Transport Security (HSTS)
 * - X-Frame-Options, X-Content-Type-Options
 * - Permissions Policy
 * - Referrer Policy
 * - And more...
 */

import type { NextFunction, Request, Response } from "express";
import { env } from "../config/env";

export function securityHeaders(req: Request, res: Response, next: NextFunction): void {
  // ════════════════════════════════════════════════════════════════
  // 1. Content Security Policy (CSP) - CRITICAL for XSS Prevention
  // ════════════════════════════════════════════════════════════════
  const cspDirectives = [
    // Default: Only same origin
    "default-src 'self'",

    // Scripts: Allow self + specific CDNs only (NO inline scripts in production!)
    env.nodeEnv === "production"
      ? "script-src 'self' https://cdn.jsdelivr.net https://cdnjs.cloudflare.com"
      : "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net https://cdnjs.cloudflare.com",

    // Styles: Allow self + inline styles (React needs this)
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",

    // Images: Allow self + data URIs + Supabase storage + external images
    "img-src 'self' data: https: blob:",

    // Fonts: Allow self + Google Fonts
    "font-src 'self' data: https://fonts.gstatic.com",

    // Connect (AJAX/Fetch/WebSocket): Allow API + Supabase + WebSocket
    `connect-src 'self' ${env.supabaseUrl} wss: ws:`,

    // Media: Allow self only
    "media-src 'self'",

    // Objects: Block all plugins (Flash, Java, etc.)
    "object-src 'none'",

    // Base URI: Prevent base tag injection
    "base-uri 'self'",

    // Form actions: Only submit to same origin
    "form-action 'self'",

    // Frame ancestors: Prevent clickjacking (same as X-Frame-Options)
    "frame-ancestors 'none'",

    // Upgrade insecure requests in production
    ...(env.nodeEnv === "production" ? ["upgrade-insecure-requests"] : []),
  ];

  res.setHeader("Content-Security-Policy", cspDirectives.join("; "));

  // ════════════════════════════════════════════════════════════════
  // 2. Strict-Transport-Security (HSTS)
  // ════════════════════════════════════════════════════════════════
  if (env.nodeEnv === "production") {
    // Force HTTPS for 2 years + include all subdomains + preload
    res.setHeader(
      "Strict-Transport-Security",
      "max-age=63072000; includeSubDomains; preload"
    );
  }

  // ════════════════════════════════════════════════════════════════
  // 3. X-Frame-Options - Prevent Clickjacking
  // ════════════════════════════════════════════════════════════════
  res.setHeader("X-Frame-Options", "DENY");

  // ════════════════════════════════════════════════════════════════
  // 4. X-Content-Type-Options - Prevent MIME Sniffing
  // ════════════════════════════════════════════════════════════════
  res.setHeader("X-Content-Type-Options", "nosniff");

  // ════════════════════════════════════════════════════════════════
  // 5. X-XSS-Protection - Legacy XSS Filter (for older browsers)
  // ════════════════════════════════════════════════════════════════
  res.setHeader("X-XSS-Protection", "1; mode=block");

  // ════════════════════════════════════════════════════════════════
  // 6. Referrer-Policy - Control referrer information
  // ════════════════════════════════════════════════════════════════
  res.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");

  // ════════════════════════════════════════════════════════════════
  // 7. Permissions-Policy - Control browser features
  // ════════════════════════════════════════════════════════════════
  const permissionsPolicy = [
    "camera=()",           // No camera access
    "microphone=()",       // No microphone access
    "geolocation=()",      // No geolocation
    "payment=()",          // No payment APIs
    "usb=()",              // No USB access
    "magnetometer=()",     // No magnetometer
    "accelerometer=()",    // No accelerometer
    "gyroscope=()",        // No gyroscope
    "interest-cohort=()",  // Block FLoC tracking
  ];
  res.setHeader("Permissions-Policy", permissionsPolicy.join(", "));

  // ════════════════════════════════════════════════════════════════
  // 8. X-DNS-Prefetch-Control - Control DNS prefetching
  // ════════════════════════════════════════════════════════════════
  res.setHeader("X-DNS-Prefetch-Control", "off");

  // ════════════════════════════════════════════════════════════════
  // 9. X-Permitted-Cross-Domain-Policies - Block Adobe products
  // ════════════════════════════════════════════════════════════════
  res.setHeader("X-Permitted-Cross-Domain-Policies", "none");

  // ════════════════════════════════════════════════════════════════
  // 10. Cross-Origin Policies
  // ════════════════════════════════════════════════════════════════
  res.setHeader("Cross-Origin-Resource-Policy", "cross-origin");

  // ════════════════════════════════════════════════════════════════
  // 11. Remove Fingerprinting Headers
  // ════════════════════════════════════════════════════════════════
  res.removeHeader("X-Powered-By");
  res.removeHeader("Server");

  // ════════════════════════════════════════════════════════════════
  // 12. Cache Control for Sensitive Data
  // ════════════════════════════════════════════════════════════════
  if (req.path.includes("/api/")) {
    res.setHeader(
      "Cache-Control",
      "no-store, no-cache, must-revalidate, proxy-revalidate"
    );
    res.setHeader("Pragma", "no-cache");
    res.setHeader("Expires", "0");
  }

  next();
}

/**
 * Security headers specifically for API routes
 */
export function apiSecurityHeaders(req: Request, res: Response, next: NextFunction): void {
  // Prevent caching of API responses
  res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, private");
  res.setHeader("Pragma", "no-cache");
  res.setHeader("Expires", "-1");

  // Prevent MIME type sniffing
  res.setHeader("X-Content-Type-Options", "nosniff");

  // Always return JSON content type
  res.setHeader("Content-Type", "application/json; charset=utf-8");

  next();
}
