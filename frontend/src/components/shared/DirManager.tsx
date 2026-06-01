"use client";

import { useEffect } from "react";
import { useTranslation } from "@/lib/i18n";

/**
 * A client component responsible for synchronizing the <html> tag's
 * 'dir' and 'lang' attributes with the selected application language.
 * This ensures RTL (Right-to-Left) support is applied globally.
 */
export function DirManager() {
  const { lang, mounted } = useTranslation();

  useEffect(() => {
    if (!mounted) return;
    
    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
    document.documentElement.lang = lang;
  }, [lang, mounted]);

  return null;
}
