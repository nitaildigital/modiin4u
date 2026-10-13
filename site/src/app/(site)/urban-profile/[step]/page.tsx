import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { getLang } from '@/lib/i18n';
import { pageMetadata, SUFFIX } from '@/lib/seo';
import { UrbanSteps, type Step } from '@/components/urban/UrbanSteps';

type Props = { params: Promise<{ step: string }> };

const STEPS: Record<string, Step> = { '1': 1, '2': 2, '3': 3, done: 'done' };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { step } = await params;
  return pageMetadata({ path: `/urban-profile/${step}/`, title: 'הפרופיל העירוני שלי' + SUFFIX, noindex: true });
}

/** /urban-profile/1/, /2/, /3/ and /done/ — the onboarding's three steps and
 *  the ready page (the app's /urban-profile/1 … /done). */
export default async function UrbanProfileStep({ params }: Props) {
  const step = STEPS[(await params).step];
  if (!step) notFound();
  return <UrbanSteps lang={await getLang()} step={step} />;
}
