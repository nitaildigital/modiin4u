// The city map's pins as its interactive part in the browser receives them,
// without the database.

export type MapLayer = 'Businesses' | 'Events' | 'Real Estate' | 'Parkings';

export type MapSlide = {
  photos: string[];
  badge: string;
  badgeColor: string;
  badgeIcon: string | null;
  headline: string;
  perMonth: string | null;
  tag: string | null;
  facts: string[];
  address: string | null;
  aboutTitle: string;
  about: string | null;
  details: [string, string][];
  route: string | null;
  /** A car park's way there, which the phone's card offers (Waze). */
  waze?: string;
};

export type CityPin = {
  id: string; layer: MapLayer; lat: number; lng: number;
  /** What the search box matches: the name (both languages for a car
   *  park), the kind of place and the address. */
  search: string;
  slide: MapSlide;
};

/** The web design's colours: blue businesses, purple events, green property;
 *  car parks take the phone frame's turquoise. */
export const LAYER_LOOK: Record<MapLayer, { pin: string; icon: string; color: string }> = {
  Businesses: { pin: '/web/map/pin_biz.svg', icon: '/web/map/layer_biz.svg', color: '#006BF6' },
  Events: { pin: '/web/map/pin_events.svg', icon: '/web/map/layer_events.svg', color: '#9032E1' },
  'Real Estate': { pin: '/web/map/pin_re.svg', icon: '/web/map/layer_re.svg', color: '#31AC4E' },
  Parkings: { pin: '/web/map/pin_parking.svg', icon: '/web/map/layer_parking.svg', color: '#17A9D0' },
};
