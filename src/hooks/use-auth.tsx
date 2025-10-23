"use client";

import { useState, useEffect, createContext, useContext, useCallback } from 'react';
import { useRouter } from 'next/navigation';

const mockUser = {
  name: 'Alex Doe',
  email: 'alex.doe@example.com',
  score: 1250,
  level: 15,
};

type AuthUser = typeof mockUser | null;

interface AuthContextType {
  user: AuthUser;
  loading: boolean;
  login: (redirect?: string) => void;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [user, setUser] = useState<AuthUser>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    // Simulate checking auth status on mount
    let authStatus: string | null = null;
    try {
      authStatus = sessionStorage.getItem('auth-status');
    } catch (error) {
      // sessionStorage is not available
    }

    if (authStatus === 'logged-in') {
      setUser(mockUser);
    }
    setLoading(false);
  }, []);

  const login = useCallback((redirect: string = '/') => {
    setLoading(true);
    setTimeout(() => {
      try {
        sessionStorage.setItem('auth-status', 'logged-in');
      } catch (error) {
        // sessionStorage is not available
      }
      setUser(mockUser);
      setLoading(false);
      router.push(redirect);
    }, 500);
  }, [router]);

  const logout = useCallback(() => {
    try {
      sessionStorage.removeItem('auth-status');
    } catch (error) {
        // sessionStorage is not available
    }
    setUser(null);
    router.push('/login');
  }, [router]);

  return (
    <AuthContext.Provider value={{ user, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
