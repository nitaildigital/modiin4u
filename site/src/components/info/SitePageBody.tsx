// The text of an information page, laid out from the three conventions the
// panel describes (site_page_body.dart): a line starting "# " or "## " is a
// heading, a line starting "- " (or "* ") is a list item, and a blank line
// starts a new paragraph. Lines inside a paragraph keep their breaks. Web and
// e-mail addresses are links — an accessibility statement has to give a way
// to reach the person responsible for it. The panel's preview draws the same
// rules, so what the client sees before publishing is what the page shows.

type Block = { kind: 'h1' | 'h2' | 'li' | 'p'; text: string };

function parse(text: string): Block[] {
  const blocks: Block[] = [];
  let para: string[] = [];
  const flush = () => { if (para.length) { blocks.push({ kind: 'p', text: para.join('\n') }); para = []; } };
  for (const raw of text.replace(/\r\n/g, '\n').split('\n')) {
    const line = raw.trim();
    if (!line) flush();
    else if (line.startsWith('## ')) { flush(); blocks.push({ kind: 'h2', text: line.slice(3).trim() }); }
    else if (line.startsWith('# ')) { flush(); blocks.push({ kind: 'h1', text: line.slice(2).trim() }); }
    else if (line.startsWith('- ') || line.startsWith('* ')) { flush(); blocks.push({ kind: 'li', text: line.slice(2).trim() }); }
    else para.push(line);
  }
  flush();
  return blocks;
}

const LINK = /(https?:\/\/[^\s]+|www\.[^\s]+|[\w.+-]+@[\w-]+(\.[\w-]+)+)/g;

/** [text] with its web and e-mail addresses made into links; a full stop or
 *  comma closing a sentence is left out of the link. */
function linked(text: string): React.ReactNode[] {
  const out: React.ReactNode[] = [];
  let start = 0;
  for (const m of text.matchAll(LINK)) {
    let link = m[0];
    const trailing = /[.,;:!?)\]]+$/.exec(link)?.[0] ?? '';
    link = link.slice(0, link.length - trailing.length);
    if (m.index! > start) out.push(text.slice(start, m.index));
    const target = link.includes('@') && !link.includes('/') ? `mailto:${link}` : link.startsWith('www.') ? `https://${link}` : link;
    out.push(<a key={m.index} href={target} className="text-midblue underline" {...(target.startsWith('http') ? { target: '_blank', rel: 'noopener' } : {})}>{link}</a>);
    start = m.index! + link.length;
  }
  if (start < text.length) out.push(text.slice(start));
  return out;
}

/** Sized from the surrounding text (16 on the desktop, 14 on the phone):
 *  every gap and heading is in ems of it. */
export function SitePageBody({ text }: { text: string }) {
  const blocks = parse(text);
  return (
    <div className="text-[#1C1C1E]">
      {blocks.map((b, i) => {
        const prev = blocks[i - 1];
        const top = i === 0 ? 0 : b.kind === 'h1' || b.kind === 'h2' ? 1.75 : b.kind === 'li' && prev?.kind === 'li' ? 0.35 : 0.9;
        if (b.kind === 'h1' || b.kind === 'h2') {
          const Tag = b.kind === 'h1' ? 'h2' : 'h3';
          const scale = b.kind === 'h1' ? 1.5 : 1.25;
          // The gap is the paragraph text's, so it is divided by the
          // heading's own size.
          return <Tag key={i} style={{ marginTop: `${top / scale}em`, fontSize: `${scale}em`, lineHeight: 1.3 }} className="font-semibold text-navy">{linked(b.text)}</Tag>;
        }
        if (b.kind === 'li') {
          return (
            <div key={i} style={{ marginTop: `${top}em` }} className="flex items-start">
              <span className="w-[1.4em] shrink-0 text-center" aria-hidden>•</span>
              <span className="flex-1">{linked(b.text)}</span>
            </div>
          );
        }
        return <p key={i} style={{ marginTop: `${top}em` }} className="whitespace-pre-line">{linked(b.text)}</p>;
      })}
    </div>
  );
}
