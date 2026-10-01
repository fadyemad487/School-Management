/**
 * Frontend Security Utilities
 *
 * Client-side security measures:
 * - XSS prevention
 * - CSRF token management
 * - Secure storage
 * - Input validation
 * - Content sanitization
 */

/**
 * Sanitize user input to prevent XSS
 */
export function sanitizeInput(input: string): string {
  if (!input) return "";

  return input
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#x27;")
    .replace(/\//g, "&#x2F;");
}

/**
 * Sanitize HTML content (strip dangerous tags)
 */
export function sanitizeHTML(html: string): string {
  if (!html) return "";

  const dangerousTags = ["script", "iframe", "object", "embed", "link", "style", "meta"];
  let sanitized = html;

  dangerousTags.forEach((tag) => {
    const regex = new RegExp(`<${tag}[^>]*>.*?<\/${tag}>`, "gis");
    sanitized = sanitized.replace(regex, "");
  });

  // Remove event handlers
  sanitized = sanitized.replace(/on\w+\s*=\s*["'][^"']*["']/gi, "");
  sanitized = sanitized.replace(/on\w+\s*=\s*[^\s>]*/gi, "");

  // Remove javascript: protocol
  sanitized = sanitized.replace(/javascript:/gi, "");

  return sanitized;
}

/**
 * Validate email format
 */
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * Validate phone number (Egyptian format)
 */
export function isValidPhone(phone: string): boolean {
  const phoneRegex = /^(01)[0-2,5]{1}[0-9]{8}$/;
  return phoneRegex.test(phone.replace(/\s/g, ""));
}

/**
 * Check password strength
 */
export function checkPasswordStrength(password: string): {
  score: number;
  feedback: string[];
  isStrong: boolean;
} {
  const feedback: string[] = [];
  let score = 0;

  // Length check
  if (password.length >= 12) {
    score += 2;
  } else if (password.length >= 8) {
    score += 1;
  } else {
    feedback.push("Password should be at least 12 characters");
  }

  // Uppercase check
  if (/[A-Z]/.test(password)) {
    score += 1;
  } else {
    feedback.push("Add uppercase letters");
  }

  // Lowercase check
  if (/[a-z]/.test(password)) {
    score += 1;
  } else {
    feedback.push("Add lowercase letters");
  }

  // Number check
  if (/[0-9]/.test(password)) {
    score += 1;
  } else {
    feedback.push("Add numbers");
  }

  // Special character check
  if (/[^A-Za-z0-9]/.test(password)) {
    score += 1;
  } else {
    feedback.push("Add special characters (!@#$%^&*)");
  }

  // Common patterns check
  const commonPatterns = ["123456", "password", "qwerty", "abc123", "letmein"];
  if (commonPatterns.some((pattern) => password.toLowerCase().includes(pattern))) {
    score -= 2;
    feedback.push("Avoid common patterns");
  }

  return {
    score: Math.max(0, Math.min(6, score)),
    feedback,
    isStrong: score >= 5,
  };
}

/**
 * Secure storage with encryption (basic XOR cipher for client-side)
 * Note: For production, consider using Web Crypto API
 */
const STORAGE_KEY = "edu_secure_";

function simpleEncrypt(text: string, key: string): string {
  let result = "";
  for (let i = 0; i < text.length; i++) {
    result += String.fromCharCode(text.charCodeAt(i) ^ key.charCodeAt(i % key.length));
  }
  return btoa(result);
}

function simpleDecrypt(encoded: string, key: string): string {
  try {
    const text = atob(encoded);
    let result = "";
    for (let i = 0; i < text.length; i++) {
      result += String.fromCharCode(text.charCodeAt(i) ^ key.charCodeAt(i % key.length));
    }
    return result;
  } catch {
    return "";
  }
}

export const secureStorage = {
  set(key: string, value: any): void {
    if (typeof window === "undefined") return;
    try {
      const serialized = JSON.stringify(value);
      const encrypted = simpleEncrypt(serialized, STORAGE_KEY);
      sessionStorage.setItem(`${STORAGE_KEY}${key}`, encrypted);
    } catch (error) {
      console.error("Secure storage set error:", error);
    }
  },

  get<T>(key: string): T | null {
    if (typeof window === "undefined") return null;
    try {
      const encrypted = sessionStorage.getItem(`${STORAGE_KEY}${key}`);
      if (!encrypted) return null;
      const decrypted = simpleDecrypt(encrypted, STORAGE_KEY);
      return JSON.parse(decrypted) as T;
    } catch (error) {
      console.error("Secure storage get error:", error);
      return null;
    }
  },

  remove(key: string): void {
    if (typeof window === "undefined") return;
    sessionStorage.removeItem(`${STORAGE_KEY}${key}`);
  },

  clear(): void {
    if (typeof window === "undefined") return;
    const keys = Object.keys(sessionStorage);
    keys.forEach((key) => {
      if (key.startsWith(STORAGE_KEY)) {
        sessionStorage.removeItem(key);
      }
    });
  },
};

/**
 * Prevent console tampering in production
 */
export function disableConsoleInProduction(): void {
  if (typeof window === "undefined") return;
  if (process.env.NODE_ENV !== "production") return;

  // Override console methods
  const noop = () => {};
  window.console.log = noop;
  window.console.warn = noop;
  window.console.error = noop;
  window.console.info = noop;
  window.console.debug = noop;
}

/**
 * Detect and block DevTools in production
 */
export function detectDevTools(): void {
  if (typeof window === "undefined") return;
  if (process.env.NODE_ENV !== "production") return;

  let devtoolsOpen = false;
  const threshold = 160;

  const check = () => {
    const widthThreshold = window.outerWidth - window.innerWidth > threshold;
    const heightThreshold = window.outerHeight - window.innerHeight > threshold;

    if (widthThreshold || heightThreshold) {
      if (!devtoolsOpen) {
        devtoolsOpen = true;
        console.warn("DevTools detected");
        // Optional: Redirect or show warning
        // window.location.href = "/access-denied";
      }
    } else {
      devtoolsOpen = false;
    }
  };

  setInterval(check, 1000);
}

/**
 * Prevent right-click and keyboard shortcuts in production
 */
export function preventInspectionShortcuts(): void {
  if (typeof window === "undefined") return;
  if (process.env.NODE_ENV !== "production") return;

  // Prevent right-click
  document.addEventListener("contextmenu", (e) => {
    e.preventDefault();
    return false;
  });

  // Prevent F12, Ctrl+Shift+I, Ctrl+Shift+J, Ctrl+U
  document.addEventListener("keydown", (e) => {
    // F12
    if (e.keyCode === 123) {
      e.preventDefault();
      return false;
    }

    // Ctrl+Shift+I, Ctrl+Shift+J, Ctrl+Shift+C
    if (e.ctrlKey && e.shiftKey && (e.keyCode === 73 || e.keyCode === 74 || e.keyCode === 67)) {
      e.preventDefault();
      return false;
    }

    // Ctrl+U (view source)
    if (e.ctrlKey && e.keyCode === 85) {
      e.preventDefault();
      return false;
    }
  });
}

/**
 * Validate file upload
 */
export function validateFileUpload(
  file: File,
  options: {
    maxSize?: number; // in bytes
    allowedTypes?: string[];
  } = {}
): { valid: boolean; error?: string } {
  const maxSize = options.maxSize || 5 * 1024 * 1024; // 5MB default
  const allowedTypes = options.allowedTypes || ["image/jpeg", "image/png", "image/jpg", "application/pdf"];

  // Check size
  if (file.size > maxSize) {
    return {
      valid: false,
      error: `File size exceeds ${Math.round(maxSize / 1024 / 1024)}MB`,
    };
  }

  // Check type
  if (!allowedTypes.includes(file.type)) {
    return {
      valid: false,
      error: "File type not allowed",
    };
  }

  // Check file name for path traversal
  if (file.name.includes("..") || file.name.includes("/") || file.name.includes("\\")) {
    return {
      valid: false,
      error: "Invalid file name",
    };
  }

  return { valid: true };
}

/**
 * Debounce function for rate limiting user actions
 */
export function debounce<T extends (...args: any[]) => any>(
  func: T,
  wait: number
): (...args: Parameters<T>) => void {
  let timeout: NodeJS.Timeout | null = null;

  return function executedFunction(...args: Parameters<T>) {
    const later = () => {
      timeout = null;
      func(...args);
    };

    if (timeout) {
      clearTimeout(timeout);
    }
    timeout = setTimeout(later, wait);
  };
}

/**
 * Throttle function for rate limiting API calls
 */
export function throttle<T extends (...args: any[]) => any>(
  func: T,
  limit: number
): (...args: Parameters<T>) => void {
  let inThrottle: boolean;

  return function executedFunction(...args: Parameters<T>) {
    if (!inThrottle) {
      func(...args);
      inThrottle = true;
      setTimeout(() => (inThrottle = false), limit);
    }
  };
}

/**
 * Generate a secure random string (for CSRF tokens, etc.)
 */
export function generateSecureToken(length: number = 32): string {
  if (typeof window === "undefined" || !window.crypto) {
    // Fallback for non-browser environments
    return Math.random().toString(36).substring(2) + Date.now().toString(36);
  }

  const array = new Uint8Array(length);
  window.crypto.getRandomValues(array);
  return Array.from(array, (byte) => byte.toString(16).padStart(2, "0")).join("");
}

/**
 * Check if running in secure context (HTTPS)
 */
export function isSecureContext(): boolean {
  if (typeof window === "undefined") return false;
  return window.isSecureContext;
}
