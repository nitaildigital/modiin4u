'use client';
import { useEffect, useState } from 'react';

/** [value], once it has stopped changing for [ms]: a search box's text for
 *  what it narrows, so a map moves (and loads its billed tiles) once per
 *  search rather than once per letter. */
export function useDebounced<T>(value: T, ms = 300): T {
  const [settled, setSettled] = useState(value);
  useEffect(() => {
    const t = setTimeout(() => setSettled(value), ms);
    return () => clearTimeout(t);
  }, [value, ms]);
  return settled;
}
