/**
 * Input Sanitization and Validation Middleware
 *
 * Protects against:
 * - XSS attacks
 * - SQL injection
 * - NoSQL injection
 * - Command injection
 * - Path traversal
 * - Prototype pollution
 * - Prompt injection (for AI inputs)
 */

import type { NextFunction, Request, Response } from "express";
import { logger } from "../utils/logger";

/**
 * Dangerous patterns to detect and block
 */
const DANGEROUS_PATTERNS = {
  // XSS patterns
  xss: [
    /<script[^>]*>[\s\S]*?<\/script>/gi,
    /javascript:/gi,
    /on\w+\s*=/gi, // Event handlers like onclick=
    /<iframe/gi,
    /<object/gi,
    /<embed/gi,
  ],

  // SQL injection patterns
  sql: [
    /(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|EXECUTE)\b)/gi,
    /(--|\/\*|\*\/|;)/g,
    /(\bOR\b|\bAND\b)\s+\d+\s*=\s*\d+/gi,
    /(\bunion\b|\bjoin\b)\s+(select|all)/gi,
  ],

  // NoSQL injection patterns
  nosql: [
    /\$where/gi,
    /\$ne/gi,
    /\$gt/gi,
    /\$lt/gi,
    /\$regex/gi,
  ],

  // Command injection patterns
  command: [
    /[;&|`$()]/g,
    /\.\.\//g, // Path traversal
  ],

  // Prototype pollution
  prototypePollution: [
    /__proto__/gi,
    /constructor/gi,
    /prototype/gi,
  ],

  // AI prompt injection patterns
  promptInjection: [
    /ignore\s+(previous|all|above)\s+(instructions|prompts|commands)/gi,
    /you\s+are\s+(now|a)\s+/gi,
    /system\s*:/gi,
    /\/imagine/gi,
    /\[system\]/gi,
    /new\s+instructions/gi,
  ],
};

/**
 * HTML entity encoding to prevent XSS
 */
function encodeHTML(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#x27;")
    .replace(/\//g, "&#x2F;");
}

/**
 * Check if string contains dangerous patterns
 */
function containsDangerousPattern(input: string, patterns: RegExp[]): boolean {
  return patterns.some((pattern) => pattern.test(input));
}

/**
 * Sanitize a single string value
 */
function sanitizeString(value: string, options: { stripHTML?: boolean; maxLength?: number } = {}): string {
  let sanitized = value.trim();

  // Enforce max length
  if (options.maxLength && sanitized.length > options.maxLength) {
    sanitized = sanitized.slice(0, options.maxLength);
  }

  // Strip HTML tags if requested
  if (options.stripHTML) {
    sanitized = sanitized.replace(/<[^>]*>/g, "");
  }

  // Encode special characters
  sanitized = encodeHTML(sanitized);

  return sanitized;
}

/**
 * Recursively sanitize object properties
 */
function sanitizeObject(obj: any, depth: number = 0): any {
  // Prevent infinite recursion
  if (depth > 10) return obj;

  if (Array.isArray(obj)) {
    return obj.map((item) => sanitizeObject(item, depth + 1));
  }

  if (obj && typeof obj === "object") {
    const sanitized: any = {};

    for (const [key, value] of Object.entries(obj)) {
      // Block prototype pollution attempts
      if (["__proto__", "constructor", "prototype"].includes(key)) {
        logger.security("Prototype pollution attempt detected", { key });
        continue;
      }

      // Sanitize key
      const sanitizedKey = sanitizeString(key, { maxLength: 100 });

      // Sanitize value
      if (typeof value === "string") {
        sanitized[sanitizedKey] = sanitizeString(value, { maxLength: 10000 });
      } else if (value && typeof value === "object") {
        sanitized[sanitizedKey] = sanitizeObject(value, depth + 1);
      } else {
        sanitized[sanitizedKey] = value;
      }
    }

    return sanitized;
  }

  return obj;
}

/**
 * Middleware to sanitize request body, query, and params
 */
export function sanitizeInput(req: Request, res: Response, next: NextFunction): void {
  try {
    // Sanitize body
    if (req.body && typeof req.body === "object") {
      req.body = sanitizeObject(req.body);
    }

    // Sanitize query params
    if (req.query && typeof req.query === "object") {
      req.query = sanitizeObject(req.query);
    }

    // Sanitize URL params
    if (req.params && typeof req.params === "object") {
      req.params = sanitizeObject(req.params);
    }

    next();
  } catch (error) {
    logger.error("Input sanitization error", error as Error);
    res.status(500).json({
      success: false,
      code: "SANITIZATION_ERROR",
      message: "Failed to process request data.",
    });
  }
}

/**
 * Middleware to detect and block malicious input patterns
 */
export function detectMaliciousInput(req: Request, res: Response, next: NextFunction): void {
  const checkValue = (value: any, path: string): boolean => {
    if (typeof value === "string") {
      // Check for XSS
      if (containsDangerousPattern(value, DANGEROUS_PATTERNS.xss)) {
        logger.security("XSS attempt detected", { path, value: value.slice(0, 100), ip: req.ip });
        return false;
      }

      // Check for SQL injection
      if (containsDangerousPattern(value, DANGEROUS_PATTERNS.sql)) {
        logger.security("SQL injection attempt detected", { path, value: value.slice(0, 100), ip: req.ip });
        return false;
      }

      // Check for NoSQL injection
      if (containsDangerousPattern(value, DANGEROUS_PATTERNS.nosql)) {
        logger.security("NoSQL injection attempt detected", { path, value: value.slice(0, 100), ip: req.ip });
        return false;
      }

      // Check for command injection
      if (containsDangerousPattern(value, DANGEROUS_PATTERNS.command)) {
        logger.security("Command injection attempt detected", { path, value: value.slice(0, 100), ip: req.ip });
        return false;
      }
    } else if (value && typeof value === "object") {
      for (const [key, val] of Object.entries(value)) {
        if (!checkValue(val, `${path}.${key}`)) {
          return false;
        }
      }
    }

    return true;
  };

  // Check body
  if (req.body && !checkValue(req.body, "body")) {
    res.status(400).json({
      success: false,
      code: "MALICIOUS_INPUT_DETECTED",
      message: "Potentially malicious input detected. Request blocked for security.",
    });
    return;
  }

  // Check query
  if (req.query && !checkValue(req.query, "query")) {
    res.status(400).json({
      success: false,
      code: "MALICIOUS_INPUT_DETECTED",
      message: "Potentially malicious input detected. Request blocked for security.",
    });
    return;
  }

  next();
}

/**
 * Specific sanitization for AI chat inputs
 */
export function sanitizeAIInput(req: Request, res: Response, next: NextFunction): void {
  const message = (req.body as any)?.message || (req.body as any)?.prompt;

  if (!message || typeof message !== "string") {
    return next();
  }

  // Check for prompt injection
  if (containsDangerousPattern(message, DANGEROUS_PATTERNS.promptInjection)) {
    logger.security("AI prompt injection attempt detected", {
      message: message.slice(0, 200),
      ip: req.ip,
      userId: req.user?.id,
    });

    res.status(400).json({
      success: false,
      code: "PROMPT_INJECTION_DETECTED",
      message: "Your message contains potentially harmful instructions and cannot be processed.",
    });
    return;
  }

  // Enforce max length for AI inputs
  const MAX_AI_INPUT_LENGTH = 4000;
  if (message.length > MAX_AI_INPUT_LENGTH) {
    res.status(400).json({
      success: false,
      code: "INPUT_TOO_LONG",
      message: `Message is too long. Maximum ${MAX_AI_INPUT_LENGTH} characters allowed.`,
    });
    return;
  }

  next();
}

/**
 * Middleware to validate file upload names
 */
export function sanitizeFileName(req: Request, res: Response, next: NextFunction): void {
  const files = (req as any).files;

  if (!files) {
    return next();
  }

  const fileArray = Array.isArray(files) ? files : [files];

  for (const file of fileArray) {
    if (!file.originalname) continue;

    // Block path traversal in filenames
    if (file.originalname.includes("..") || file.originalname.includes("/") || file.originalname.includes("\\")) {
      logger.security("Path traversal attempt in filename", {
        filename: file.originalname,
        ip: req.ip,
      });

      res.status(400).json({
        success: false,
        code: "INVALID_FILENAME",
        message: "Invalid filename detected.",
      });
      return;
    }
  }

  next();
}
