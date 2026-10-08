import { Header } from '@/components/chrome/Header';

/** Every page but the home page: the white bar on top. */
export default function SiteLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      <Header />
      <main>{children}</main>
    </>
  );
}
