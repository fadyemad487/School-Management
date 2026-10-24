export const STRONG_PASSWORD_PATTERN = /^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[^A-Za-z0-9\s])[\s\S]+$/;

export function isStrongPassword(password: string) {
  return password.length >= 8 && password.length <= 128 && STRONG_PASSWORD_PATTERN.test(password);
}

export function passwordPolicyMessage(isAr: boolean) {
  return isAr
    ? "أنشئ كلمة مرور من 8 أحرف على الأقل، تتضمن حرفًا كبيرًا وصغيرًا ورقمًا ورمزًا خاصًا."
    : "Create a password with at least 8 characters, including uppercase and lowercase letters, a number, and a symbol.";
}
