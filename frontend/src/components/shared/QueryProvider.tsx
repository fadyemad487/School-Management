"use client";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useState } from "react";

export default function QueryProvider({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 30 * 1000, // Keep data fresh for 30s so transitions are instantaneous
        gcTime: 10 * 60 * 1000, // Keep cache for 10 minutes
        refetchOnMount: "always",
        refetchOnWindowFocus: false, // Avoid redundant network calls on tab focus
        refetchOnReconnect: true,
        retry: 1,
      },
    },
  }));

  return (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
}
