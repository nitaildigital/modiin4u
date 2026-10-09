'use client';
import { useEffect } from 'react';
import { trackArticleView } from '@/components/business/stats';

/** Counts the reader's view of the article, once the page is in the browser. */
export function ArticleView({ id }: { id: string }) {
  useEffect(() => { trackArticleView(id); }, [id]);
  return null;
}
