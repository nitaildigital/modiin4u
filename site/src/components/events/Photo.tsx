import type { ComponentType } from 'react';

type IconProps = { size?: number | string; color?: string; variant?: 'Linear' | 'Outline' | 'Broken' | 'Bold' | 'Bulk' | 'TwoTone' };

/** A remote photograph, or — where the row has none — the brand's navy
 *  gradient with a faint glyph, as the app's NetworkPhoto draws a missing
 *  picture. Events and deals share it. */
export function Photo({ url, alt = '', className = '', icon: Icon, iconSize = 32, eager = false }: {
  url: string | null | undefined; alt?: string; className?: string;
  icon?: ComponentType<IconProps>; iconSize?: number; eager?: boolean;
}) {
  if (url) {
    return <img src={url} alt={alt} loading={eager ? 'eager' : 'lazy'} className={`object-cover ${className}`} />;
  }
  return (
    <div className={`flex items-center justify-center ${className}`} style={{ background: 'linear-gradient(135deg, #0058B5, #010A36)' }} aria-hidden>
      {Icon && <Icon size={iconSize} color="rgba(255,255,255,0.28)" variant="Bold" />}
    </div>
  );
}
