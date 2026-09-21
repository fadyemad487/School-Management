import Redis from "ioredis";

const redisUrl = process.env.REDIS_URL || "redis://localhost:6379";
const isRedisEnabled = process.env.ENABLE_REDIS === "true" || process.env.NODE_ENV === "production" || Boolean(process.env.REDIS_URL);

let redisClient: Redis | null = null;
let redisSubClient: Redis | null = null;
let isConnected = false;

if (isRedisEnabled) {
  try {
    redisClient = new Redis(redisUrl, {
      maxRetriesPerRequest: 1,
      enableReadyCheck: true,
      retryStrategy(times) {
        if (times > 3) {
          // Do not retry indefinitely in development if Redis isn't running
          return null;
        }
        return Math.min(times * 200, 1000);
      },
      lazyConnect: true
    });

    redisClient.on("connect", () => {
      isConnected = true;
      console.log("⚡ [Redis] Connected successfully to:", redisUrl.replace(/\/\/.*@/, "//***@"));
    });

    redisClient.on("error", (err) => {
      isConnected = false;
      // Graceful warning without crashing server
      console.warn("⚠️ [Redis] Connection warning (running in in-memory fallback):", err.message);
    });

    // Attempt non-blocking connection
    redisClient.connect().catch(() => {
      // Handled by error event
    });
  } catch (err: any) {
    console.warn("⚠️ [Redis] Initialization skipped:", err.message);
    redisClient = null;
  }
}

export function getRedisClient(): Redis | null {
  return isConnected ? redisClient : null;
}

export function createRedisSubClient(): Redis | null {
  if (!isRedisEnabled) return null;
  try {
    const sub = new Redis(redisUrl, {
      maxRetriesPerRequest: 1,
      lazyConnect: true
    });
    sub.on("error", () => {});
    sub.connect().catch(() => {});
    return sub;
  } catch {
    return null;
  }
}

/**
 * Cache Helper: Get deserialized JSON from Redis
 */
export async function cacheGet<T>(key: string): Promise<T | null> {
  const client = getRedisClient();
  if (!client) return null;
  try {
    const data = await client.get(key);
    return data ? JSON.parse(data) : null;
  } catch {
    return null;
  }
}

/**
 * Cache Helper: Set JSON in Redis with optional TTL (seconds)
 */
export async function cacheSet(key: string, value: any, ttlSeconds: number = 300): Promise<void> {
  const client = getRedisClient();
  if (!client) return;
  try {
    const serialized = JSON.stringify(value);
    if (ttlSeconds > 0) {
      await client.set(key, serialized, "EX", ttlSeconds);
    } else {
      await client.set(key, serialized);
    }
  } catch {}
}

/**
 * Cache Helper: Invalidate key or pattern
 */
export async function cacheDel(key: string): Promise<void> {
  const client = getRedisClient();
  if (!client) return;
  try {
    await client.del(key);
  } catch {}
}

export const redis = {
  get: cacheGet,
  set: cacheSet,
  del: cacheDel,
  getClient: getRedisClient
};
