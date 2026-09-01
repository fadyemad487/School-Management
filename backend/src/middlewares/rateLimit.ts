import type { NextFunction, Request, Response } from "express";

type RateLimitOptions = {
  windowMs: number;
  max: number;
  message: string;
};

type Entry = { count: number; resetAt: number };

/**
 * Small dependency-free limiter for public authentication endpoints. The
 * production edge/platform should still provide a distributed limiter; this
 * prevents straightforward password guessing on each API instance.
 */
export function createRateLimiter(options: RateLimitOptions) {
  const requests = new Map<string, Entry>();

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
