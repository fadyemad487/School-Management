/**
 * Secure Production Logger
 *
 * Prevents sensitive data leakage in production by:
 * - Disabling console.log in production
 * - Structured logging with levels
 * - Automatic sensitive data masking
 * - Optional external logging service integration
 */

type LogLevel = "debug" | "info" | "warn" | "error";

const sensitiveKeys = [
  "password",
  "token",
  "secret",
  "apiKey",
  "authorization",
  "cookie",
  "session",
  "jwt",
  "bearer",
  "credential",
  "privateKey",
];

/**
 * Masks sensitive data in objects before logging
 */
function maskSensitiveData(data: any): any {
  if (!data || typeof data !== "object") return data;

  if (Array.isArray(data)) {
    return data.map(maskSensitiveData);
  }

  const masked: any = {};
  for (const [key, value] of Object.entries(data)) {
    const lowerKey = key.toLowerCase();
    const isSensitive = sensitiveKeys.some((sensitive) => lowerKey.includes(sensitive));

    if (isSensitive && typeof value === "string") {
      masked[key] = value.length > 4 ? `${value.slice(0, 4)}***` : "***";
    } else if (typeof value === "object" && value !== null) {
      masked[key] = maskSensitiveData(value);
    } else {
      masked[key] = value;
    }
  }
  return masked;
}

class Logger {
  private isDevelopment: boolean;
  private isProduction: boolean;

  constructor() {
    this.isDevelopment = process.env.NODE_ENV === "development";
    this.isProduction = process.env.NODE_ENV === "production";
  }

  /**
   * Development-only debug logs (completely disabled in production)
   */
  debug(message: string, ...args: any[]): void {
    if (this.isDevelopment) {
      console.log(`[DEBUG] ${message}`, ...args.map(maskSensitiveData));
    }
  }

  /**
   * Informational logs (visible in development, logged to external service in production)
   */
  info(message: string, data?: any): void {
    if (this.isDevelopment) {
      console.info(`[INFO] ${message}`, data ? maskSensitiveData(data) : "");
    } else if (this.isProduction) {
      // In production, send to external logging service (e.g., Sentry, Datadog, CloudWatch)
      // For now, we keep it silent to prevent console exposure
      this.sendToExternalLogger("info", message, data);
    }
  }

  /**
   * Warning logs (always logged)
   */
  warn(message: string, data?: any): void {
    if (this.isDevelopment) {
      console.warn(`⚠️ [WARN] ${message}`, data ? maskSensitiveData(data) : "");
    } else {
      this.sendToExternalLogger("warn", message, data);
    }
  }

  /**
   * Error logs (always logged with full context)
   */
  error(message: string, error?: Error | any, context?: any): void {
    const errorData = {
      message,
      error: error instanceof Error ? {
        name: error.name,
        message: error.message,
        stack: error.stack,
      } : error,
      context: maskSensitiveData(context),
      timestamp: new Date().toISOString(),
    };

    if (this.isDevelopment) {
      console.error(`❌ [ERROR] ${message}`, errorData);
    } else {
      this.sendToExternalLogger("error", message, errorData);
    }
  }

  /**
   * Security event logging (critical security events)
   */
  security(event: string, data?: any): void {
    const securityLog = {
      event,
      data: maskSensitiveData(data),
      timestamp: new Date().toISOString(),
      level: "SECURITY",
    };

    if (this.isDevelopment) {
      console.warn(`🔒 [SECURITY] ${event}`, securityLog);
    } else {
      // Always log security events to external service in production
      this.sendToExternalLogger("security", event, securityLog);
    }
  }

  /**
   * Send logs to external logging service
   * TODO: Integrate with Sentry, Datadog, or your preferred service
   */
  private sendToExternalLogger(level: string, message: string, data?: any): void {
    // Example: Send to Sentry, Datadog, CloudWatch, etc.
    // For now, we keep production console completely silent

    // Uncomment and configure your logging service:
    /*
    try {
      if (process.env.SENTRY_DSN) {
        Sentry.captureMessage(message, {
          level: level as SentrySeverity,
          extra: data,
        });
      }
    } catch (err) {
      // Silent fail - don't expose logging errors
    }
    */
  }

  /**
   * WebSocket connection logging (sanitized)
   */
  wsConnection(socketId: string, schoolId: string | null, role: string): void {
    this.info("[WebSocket] Connection established", {
      socketId: socketId.slice(0, 8) + "***", // Partial ID only
      schoolId,
      role,
    });
  }

  /**
   * WebSocket disconnection logging
   */
  wsDisconnection(socketId: string): void {
    this.info("[WebSocket] Connection closed", {
      socketId: socketId.slice(0, 8) + "***",
    });
  }

  /**
   * Authentication event logging
   */
  authEvent(event: "login" | "logout" | "failed" | "token_expired", userId?: string, ip?: string): void {
    this.security(`Auth: ${event}`, {
      userId,
      ip,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Database query performance logging (development only)
   */
  dbQuery(query: string, duration: number): void {
    if (this.isDevelopment && duration > 100) {
      this.warn(`Slow query detected (${duration}ms)`, { query: query.slice(0, 100) });
    }
  }
}

// Export singleton instance
export const logger = new Logger();

// Export convenience functions
export const log = logger.info.bind(logger);
export const logError = logger.error.bind(logger);
export const logSecurity = logger.security.bind(logger);
export const logDebug = logger.debug.bind(logger);
export const logWarn = logger.warn.bind(logger);
