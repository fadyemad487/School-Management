import type { NextFunction, Request, Response } from "express";

type RateLimitOptions = {
  windowMs: number;
  max: number;
  message: string;
};

type Entry = { count: number; resetAt: number };

/**
 * Lightweight in-memory rate limiter with automatic cleanup
 */
export function createRateLimiter(options: RateLimitOptions) {
  const requests = new Map<string, Entry>();

  // Periodically sweep expired entries to prevent memory leaks
  const interval = setInterval(() => {
    const now = Date.now();
    for (const [key, entry] of requests.entries()) {
      if (entry.resetAt <= now) {
        requests.delete(key);
      }
    }
  }, Math.max(30_000, options.windowMs));
  if (interval.unref) interval.unref();

  return (req: Request, res: Response, next: NextFunction): void => {
    const now = Date.now();
    const key = req.ip || req.socket.remoteAddress || "unknown";
    const current = requests.get(key);

    if (!current || current.resetAt <= now) {
      requests.set(key, { count: 1, resetAt: now + options.windowMs });
      next();
      return;
    }

    current.count += 1;
    if (current.count > options.max) {
      const retryAfter = Math.max(1, Math.ceil((current.resetAt - now) / 1000));
      res.setHeader("Retry-After", String(retryAfter));
      res.status(429).json({ success: false, code: "RATE_LIMIT", message: options.message });
      return;
    }

    next();
  };
}

/** General API rate limiter: 300 requests per 15 minutes per IP */
export const apiLimiter = createRateLimiter({
  windowMs: 15 * 60 * 1000,
  max: 300,
  message: "Too many requests from this IP, please try again later."
});
