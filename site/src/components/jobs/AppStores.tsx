/** The two store badges (the landing page's), linked where the panel holds
 *  the stores' addresses; drawn without a link until it does. */
export function AppStores({ ios, android }: { ios: string | null; android: string | null }) {
  const badge = (link: string | null, src: string, alt: string) => {
    const img = <img src={`/web/app-landing/${src}`} alt={alt} width={179} height={56} className="block h-11 w-auto" />;
    return link ? <a href={link} target="_blank" rel="noopener">{img}</a> : <span>{img}</span>;
  };
  return (
    <div dir="ltr" className="flex flex-wrap justify-center gap-3">
      {badge(ios, 'badge_app_store.svg', 'Download on the App Store')}
      {badge(android, 'badge_google_play.svg', 'Get it on Google Play')}
    </div>
  );
}
