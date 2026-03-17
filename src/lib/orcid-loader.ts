import type { Loader } from 'astro/loaders';
import extras from '../data/publication-extras.json';

const ORCID_ID = '0000-0001-7678-3716';
const ORCID_API = `https://pub.orcid.org/v3.0/${ORCID_ID}`;

interface OrcidWorkSummary {
  'put-code': number;
  title: { title: { value: string } };
  'journal-title': { value: string } | null;
  'publication-date': {
    year: { value: string } | null;
    month: { value: string } | null;
    day: { value: string } | null;
  } | null;
  'external-ids': {
    'external-id': Array<{
      'external-id-type': string;
      'external-id-value': string;
    }>;
  };
}

interface OrcidContributor {
  'credit-name': { value: string } | null;
}

interface OrcidWorkDetail {
  contributors: { contributor: OrcidContributor[] } | null;
}

const extrasMap = extras as Record<string, { paperurl?: string; code?: string; github?: string }>;

async function fetchJson(url: string) {
  const res = await fetch(url, { headers: { Accept: 'application/json' } });
  if (!res.ok) throw new Error(`ORCID API error: ${res.status} ${url}`);
  return res.json();
}

function getDoi(summary: OrcidWorkSummary): string | undefined {
  return summary['external-ids']['external-id']
    .find((id) => id['external-id-type'] === 'doi')
    ?.['external-id-value'];
}

function parseDate(pubDate: OrcidWorkSummary['publication-date']): string {
  if (!pubDate?.year?.value) return '1970-01-01';
  const y = pubDate.year.value;
  const m = pubDate.month?.value ?? '01';
  const d = pubDate.day?.value ?? '01';
  return `${y}-${m.padStart(2, '0')}-${d.padStart(2, '0')}`;
}

function formatAuthors(contributors: OrcidContributor[], ownerName: string): string {
  return contributors
    .map((c) => {
      const name = c['credit-name']?.value ?? '';
      if (name.toLowerCase().includes('brainard')) {
        return `<strong>${name}</strong>`;
      }
      return name;
    })
    .filter(Boolean)
    .join(', ');
}

export function orcidLoader(): Loader {
  return {
    name: 'orcid-publications',
    async load({ store, logger }) {
      logger.info('Fetching publications from ORCID...');

      const worksData = await fetchJson(`${ORCID_API}/works`);
      const groups: Array<{ 'work-summary': OrcidWorkSummary[] }> = worksData.group;

      for (const group of groups) {
        const summary = group['work-summary'][0];
        const putCode = summary['put-code'];
        const doi = getDoi(summary);
        const doiNormalized = doi?.toLowerCase();

        // Fetch full work detail for contributors
        const detail: OrcidWorkDetail = await fetchJson(
          `${ORCID_API}/work/${putCode}`
        );

        const contributors = detail.contributors?.contributor ?? [];
        const authorStr = formatAuthors(contributors, 'Brainard');
        const title = summary.title.title.value;
        const venue = summary['journal-title']?.value ?? '';
        const dateStr = parseDate(summary['publication-date']);
        const year = summary['publication-date']?.year?.value ?? '';

        const citation = `${authorStr}. ${title}. <em>${venue}</em> (${year})`;
        const link = doi ? `https://doi.org/${doi}` : undefined;

        // Look up extras by normalized DOI
        const extra = doiNormalized ? extrasMap[doiNormalized] : undefined;

        store.set({
          id: doi ?? `orcid-${putCode}`,
          data: {
            title,
            date: dateStr,
            venue,
            link,
            citation,
            paperurl: extra?.paperurl,
            code: extra?.code,
            github: extra?.github,
          },
        });
      }

      logger.info(`Loaded ${groups.length} publications from ORCID`);
    },
  };
}
