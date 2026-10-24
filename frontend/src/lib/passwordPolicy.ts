export const STRONG_PASSWORD_PATTERN = /^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[^A-Za-z0-9\s])[\s\S]+$/;

export function isStrongPassword(password: string) {
  return password.length >= 8 && password.length <= 128 && STRONG_PASSWORD_PATTERN.test(password);
}

export function passwordPolicyMessage(isAr: boolean) {
  return isAr
    ? "اختر كلمة مرور قوية للحفاظ على أمان حسابك."
    : "Choose a strong password to keep your account secure.";
}
