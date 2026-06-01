import { Role } from "@prisma/client";

declare global {
  namespace Express {
    interface Request {
      user?: {
        id: string;
        supabaseId: string;
        email: string;
        role: Role;
        schoolId: string | null;
      };
      /** Shortcut to req.user.id — set by auth middleware */
      userId?: string;
      /** Set by tenantScope middleware. null = SUPER_ADMIN (all schools). */
      schoolId: string | null;
    }
  }
}

export {};
