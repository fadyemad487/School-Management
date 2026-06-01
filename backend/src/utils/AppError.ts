/**
 * Base application error class with structured error information.
 * All custom errors should extend this class.
 */
export class AppError extends Error {
  public readonly statusCode: number;
  public readonly code: string;
  public readonly field?: string;
  public readonly isOperational: boolean;

  constructor(
    message: string,
    statusCode: number,
    code: string,
    field?: string
  ) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.field = field;
    this.isOperational = true;
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

/** 400 — Validation error (missing or invalid fields) */
export class ValidationError extends AppError {
  constructor(message: string, field?: string) {
    super(message, 400, "VALIDATION_ERROR", field);
  }
}

/** 401 — Authentication failed */
export class AuthenticationError extends AppError {
  constructor(message: string, code: string = "AUTH_ERROR", field?: string) {
    super(message, 401, code, field);
  }
}

/** 403 — Not authorized for this resource */
export class ForbiddenError extends AppError {
  constructor(message: string = "You don't have permission to access this resource.") {
    super(message, 403, "FORBIDDEN");
  }
}

/** 404 — Resource not found */
export class NotFoundError extends AppError {
  constructor(resource: string = "Resource") {
    super(`${resource} not found.`, 404, "NOT_FOUND");
  }
}

/** 409 — Conflict (duplicate entry) */
export class ConflictError extends AppError {
  constructor(message: string, field?: string) {
    super(message, 409, "CONFLICT", field);
  }
}

/** 429 — Too many requests */
export class RateLimitError extends AppError {
  constructor(message: string = "Too many requests. Please try again later.") {
    super(message, 429, "RATE_LIMIT");
  }
}
