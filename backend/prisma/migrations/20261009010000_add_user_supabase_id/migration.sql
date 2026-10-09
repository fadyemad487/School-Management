ALTER TABLE "User"
ADD COLUMN "supabaseId" TEXT;

CREATE UNIQUE INDEX "User_supabaseId_key" ON "User"("supabaseId");
