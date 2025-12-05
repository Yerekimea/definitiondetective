import RootLayout from '../src/app/layout';

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return <RootLayout>{children}</RootLayout>;
}
