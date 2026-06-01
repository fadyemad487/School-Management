"use client";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useState } from "react";

export default function QueryProvider({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 0, // Data is considered immediately stale for silent background updates
        refetchOnMount: true, // Seamlessly refresh data in background upon page mount/navigation
        refetchOnWindowFocus: true, // Seamlessly refresh when switching back to the browser tab
        refetchOnReconnect: true, // Seamlessly refresh when internet reconnects
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
