'use client';
import { Children, useEffect, useState } from 'react';
import { distance, watchPosition, type Position } from '@/lib/near';

/** Its children in the server's order until the visitor's position is known,
 *  then nearest first (those without a place keep their order, after).
 *  `points` follows the children, one each; `limit` shows only the first
 *  so many of that order. */
export function NearRow({ points, limit, children }: { points: ([number, number] | null)[]; limit?: number; children: React.ReactNode }) {
  const [at, setAt] = useState<Position | null>(null);
  useEffect(() => watchPosition(setAt), []);
  const items = Children.toArray(children);
  if (!at) return <>{items.slice(0, limit)}</>;
  const order = items.map((el, i) => {
    const p = points[i];
    return { el, i, d: p ? distance(at, { lat: p[0], lng: p[1] }) : Infinity };
  }).sort((a, b) => a.d - b.d || a.i - b.i);
  return <>{order.slice(0, limit).map((o) => o.el)}</>;
}
