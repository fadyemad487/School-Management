const configuredMaxTokens = Number(process.env.OPENROUTER_MAX_TOKENS);

export const OPENROUTER_MODEL =
  process.env.OPENROUTER_MODEL?.trim() || "recursive/flint-v1.0:free";

export const OPENROUTER_MAX_TOKENS =
  Number.isInteger(configuredMaxTokens) && configuredMaxTokens > 0
    ? Math.min(configuredMaxTokens, 8192)
    : 4096;
