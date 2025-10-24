"use client";

import type { FC, ReactNode } from "react";
import { Toaster } from "@/components/ui/toaster";
import { AuthProvider } from '@/hooks/use-auth';
import { SoundProvider } from "@/hooks/use-sound";

interface ProvidersProps {
  children: ReactNode;
}

const Providers: FC<ProvidersProps> = ({ children }) => {
  return (
    <AuthProvider>
      <SoundProvider>
        {children}
        <Toaster />
      </SoundProvider>
    </AuthProvider>
  );
};

export default Providers;
