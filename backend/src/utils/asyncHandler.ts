import type { NextFunction, Request, Response } from "express";

/**
 * Wraps an async route handler to automatically catch errors
 * and forward them to Express error middleware.
 * Eliminates the need for try/catch in every controller.
 */
export const asyncHandler = (
  fn: (req: Request, res: Response, next: NextFunction) => Promise<any>
) => {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};
