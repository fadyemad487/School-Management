import type { NextFunction, Request, Response } from "express";
import { AppError } from "../utils/AppError";
import { ZodError } from "zod";
import { Prisma } from "@prisma/client";

/**
 * Global error handler middleware.
 * 
 * Catches all errors thrown or forwarded via next(err) and returns
 * a structured JSON response. Handles:
 *   - AppError (our custom errors) → returns code, message, field
 *   - ZodError (validation) → maps to field-level messages
 *   - Prisma errors (unique constraint, etc.) → clean conflict messages
 *   - JWT errors → authentication messages
 *   - Unknown errors → generic 500
 */
export function errorHandler(
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
): void {
  // ── Our custom AppError hierarchy ──
  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      success: false,
      code: err.code,
      message: err.message,
      ...(err.field && { field: err.field })
    });
    return;
  }

  // ── Zod validation errors ──
  if (err instanceof ZodError) {
    const firstIssue = err.issues[0];
    const field = firstIssue?.path?.join(".") || undefined;
    res.status(400).json({
      success: false,
      code: "VALIDATION_ERROR",
      message: firstIssue?.message || "Invalid input data.",
      field,
      errors: err.issues.map((issue) => ({
        field: issue.path.join("."),
        message: issue.message
      }))
    });
    return;
  }

  // ── Prisma unique constraint violation ──
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    if (err.code === "P2002") {
      const target = (err.meta?.target as string[]) || [];
      const fieldName = target[0] || "field";
      const friendlyNames: Record<string, string> = {
        email: "An account with this email already exists.",
        code: "This School ID is already registered. Each school must have a unique ID."
      };
      res.status(409).json({
        success: false,
        code: "CONFLICT",
        message: friendlyNames[fieldName] || `A record with this ${fieldName} already exists.`,
        field: fieldName
      });
      return;
    }

    if (err.code === "P2025") {
      res.status(404).json({
        success: false,
        code: "NOT_FOUND",
        message: "The requested record was not found."
      });
      return;
    }
  }

  // ── JWT errors ──
  if (err.name === "JsonWebTokenError") {
    res.status(401).json({
      success: false,
      code: "INVALID_TOKEN",
      message: "Your session is invalid. Please sign in again."
    });
    return;
  }

  if (err.name === "TokenExpiredError") {
    res.status(401).json({
      success: false,
      code: "TOKEN_EXPIRED",
      message: "Your session has expired. Please sign in again."
    });
    return;
  }

  // ── Unknown / unhandled errors ──
  console.error("[ErrorHandler] Unhandled error:", err);
  res.status(500).json({
    success: false,
    code: "INTERNAL_ERROR",
    message: "An unexpected error occurred. Please try again later."
  });
}
