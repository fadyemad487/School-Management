export const STRONG_PASSWORD_PATTERN = /^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[^A-Za-z0-9\s])[\s\S]+$/;

export function isStrongPassword(password: string) {
  return password.length >= 8 && password.length <= 128 && STRONG_PASSWORD_PATTERN.test(password);
}

export function passwordPolicyMessage(isAr: boolean) {
  return isAr
    ? "كلمة المرور لازم تكون 8 أحرف على الأقل وبحد أقصى 128، وتحتوي على حرف صغير وحرف كبير ورقم ورمز خاص."
    : "Use 8–128 characters with at least one lowercase letter, uppercase letter, number, and symbol.";
}
