/**
 * Advanced Rate Limiting with Redis Support
 *
 * Features:
 * - Distributed rate limiting with Redis
 * - Endpoint-specific limits
 * - Brute-force protection
 * - Sliding window algorithm
 * - IP-based + User-based limiting
 * - Automatic lockout for suspicious activity
 */

import type { NextFunction, Request, Response } from "express";
import { getRedisClient } from "../config/redis";
import { logger } from "../utils/logger";

interface RateLimitConfig {
  windowMs: number;
  maxRequests: number;
  message?: string;
  skipSuccessfulRequests?: boolean;
  keyGenerator?: (req: Request) => string;
}

/**
 * Generate a unique key for rate limiting
 */
function defaultKeyGenerator(req: Request): string {
  // Use user ID if authenticated, otherwise IP
  return req.user?.id || req.ip || "unknown";
}

/**
 * Create a Redis-based rate limiter with sliding window
 */
export function createRedisRateLimiter(config: RateLimitConfig) {
  const redis = getRedisClient();

  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    const key = (config.keyGenerator || defaultKeyGenerator)(req);
    const rateLimitKey = `ratelimit:${key}:${req.path}`;
    const now = Date.now();
    const windowStart = now - config.windowMs;

    try {
      if (!redis) {
        // Fallback to in-memory if Redis is not available
        logger.warn("Redis not available, skipping rate limit");
        return next();
      }

      // Remove old entries outside the window
      await redis.zremrangebyscore(rateLimitKey, 0, windowStart);

      // Count requests in current window
      const requestCount = await redis.zcard(rateLimitKey);

      // Check if limit exceeded
      if (requestCount >= config.maxRequests) {
        const oldestRequest = await redis.zrange(rateLimitKey, "0", "0", "WITHSCORES");
        const resetTime = oldestRequest[1] ? parseInt(oldestRequest[1]) + config.windowMs : now + config.windowMs;
        const retryAfter = Math.ceil((resetTime - now) / 1000);

        logger.security("Rate limit exceeded", {
          key,
          path: req.path,
          method: req.method,
          ip: req.ip,
          requestCount,
          limit: config.maxRequests,
        });

        res.setHeader("Retry-After", String(retryAfter));
        res.setHeader("X-RateLimit-Limit", String(config.maxRequests));
        res.setHeader("X-RateLimit-Remaining", "0");
        res.setHeader("X-RateLimit-Reset", String(Math.ceil(resetTime / 1000)));

        res.status(429).json({
          success: false,
          code: "RATE_LIMIT_EXCEEDED",
          message: config.message || "Too many requests. Please try again later.",
          retryAfter,
        });
        return;
      }

      // Add current request to the window
      await redis.zadd(rateLimitKey, String(now), `${now}-${Math.random()}`);
      await redis.expire(rateLimitKey, Math.ceil(config.windowMs / 1000));

      // Set rate limit headers
      res.setHeader("X-RateLimit-Limit", String(config.maxRequests));
      res.setHeader("X-RateLimit-Remaining", String(config.maxRequests - requestCount - 1));
      res.setHeader("X-RateLimit-Reset", String(Math.ceil((now + config.windowMs) / 1000)));

      next();
    } catch (error) {
      logger.error("Rate limiter error", error as Error);
      // Don't block requests on rate limiter errors
      next();
    }
  };
}

/**
 * Strict rate limiter for authentication endpoints (prevent brute force)
 */
export const authRateLimiter = createRedisRateLimiter({
  windowMs: 15 * 60 * 1000, // 15 minutes
  maxRequests: 5, // Only 5 attempts per 15 minutes
  message: "Too many login attempts. Please try again in 15 minutes.",
  keyGenerator: (req) => {
    // Rate limit by IP + email combination
    const email = (req.body as any)?.email?.toLowerCase() || "";
    return `auth:${req.ip}:${email}`;
  },
});

/**
 * Strict rate limiter for password reset
 */
export const passwordResetRateLimiter = createRedisRateLimiter({
  windowMs: 60 * 60 * 1000, // 1 hour
  maxRequests: 3, // Only 3 attempts per hour
  message: "Too many password reset attempts. Please try again in 1 hour.",
});

/**
 * Standard API rate limiter (general endpoints)
 */
export const apiRateLimiter = createRedisRateLimiter({
  windowMs: 15 * 60 * 1000, // 15 minutes
  maxRequests: 300, // 300 requests per 15 minutes
  message: "Too many requests. Please slow down.",
});

/**
 * Strict rate limiter for write operations (POST/PUT/DELETE)
 */
export const writeRateLimiter = createRedisRateLimiter({
  windowMs: 1 * 60 * 1000, // 1 minute
  maxRequests: 30, // 30 writes per minute
  message: "Too many write operations. Please wait a moment.",
});

/**
 * Lenient rate limiter for read operations (GET)
 */
export const readRateLimiter = createRedisRateLimiter({
  windowMs: 1 * 60 * 1000, // 1 minute
  maxRequests: 100, // 100 reads per minute
  message: "Too many read requests. Please wait a moment.",
});

/**
 * Very strict rate limiter for sensitive operations
 */
export const sensitiveOperationRateLimiter = createRedisRateLimiter({
  windowMs: 60 * 60 * 1000, // 1 hour
  maxRequests: 10, // Only 10 sensitive operations per hour
  message: "Too many sensitive operations. Please try again later.",
});

/**
 * Rate limiter for AI chat (prevent API abuse)
 */
export const aiChatRateLimiter = createRedisRateLimiter({
  windowMs: 1 * 60 * 1000, // 1 minute
  maxRequests: 10, // 10 AI messages per minute
  message: "Too many AI requests. Please wait before sending more messages.",
});

/**
 * Account lockout system for repeated failed login attempts
 */
export class AccountLockout {
  private static readonly LOCKOUT_DURATION = 30 * 60 * 1000; // 30 minutes
  private static readonly MAX_ATTEMPTS = 5;

  static async recordFailedAttempt(identifier: string): Promise<boolean> {
    const redis = getRedisClient();
    if (!redis) return false;

    const key = `lockout:${identifier}`;
    const attempts = await redis.incr(key);

    if (attempts === 1) {
      await redis.expire(key, Math.ceil(this.LOCKOUT_DURATION / 1000));
    }

    if (attempts >= this.MAX_ATTEMPTS) {
      logger.security("Account locked due to failed attempts", {
        identifier,
        attempts,
        duration: this.LOCKOUT_DURATION / 1000,
      });
      return true; // Account is locked
    }

    return false;
  }

  static async isLocked(identifier: string): Promise<boolean> {
    const redis = getRedisClient();
    if (!redis) return false;

    const key = `lockout:${identifier}`;
    const attempts = await redis.get(key);
    return attempts ? parseInt(attempts) >= this.MAX_ATTEMPTS : false;
  }

  static async clearAttempts(identifier: string): Promise<void> {
    const redis = getRedisClient();
    if (!redis) return;

    const key = `lockout:${identifier}`;
    await redis.del(key);
  }

  static async getRemainingAttempts(identifier: string): Promise<number> {
    const redis = getRedisClient();
    if (!redis) return this.MAX_ATTEMPTS;

    const key = `lockout:${identifier}`;
    const attempts = await redis.get(key);
    const current = attempts ? parseInt(attempts) : 0;
    return Math.max(0, this.MAX_ATTEMPTS - current);
  }
}
