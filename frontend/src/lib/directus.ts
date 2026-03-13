import type {
  Kat,
  Kitten,
  Nest,
  BlogBericht,
  Pagina,
  SiteInstellingen,
  VeelgesteldeVraag,
  Ervaring,
} from './types';

const DIRECTUS_URL = import.meta.env.DIRECTUS_URL || 'http://localhost:8055';

// Public-facing URLs — relative paths so they work behind any reverse proxy
export function getDirectusURL(path: string = ''): string {
  return path;
}

interface ImageOptions {
  width?: number;
  height?: number;
  fit?: 'cover' | 'contain' | 'inside' | 'outside';
  format?: 'webp' | 'jpg' | 'png' | 'avif';
  quality?: number;
}

export function getImageURL(id: string, opts: ImageOptions = {}): string {
  const params = new URLSearchParams();
  if (opts.width) params.set('width', String(opts.width));
  if (opts.height) params.set('height', String(opts.height));
  if (opts.fit) params.set('fit', opts.fit);
  if (opts.format) params.set('format', opts.format);
  if (opts.quality) params.set('quality', String(opts.quality));
  const query = params.toString();
  return `/assets/${id}${query ? `?${query}` : ''}`;
}

// Build-time fetch uses internal URL directly
async function fetchDirectus<T>(path: string): Promise<T> {
  const res = await fetch(`${DIRECTUS_URL}${path}`);
  if (!res.ok) {
    throw new Error(`Directus fetch failed: ${res.status} ${res.statusText}`);
  }
  const json = await res.json();
  return json.data as T;
}

// --- Katten ---

const katFields = '*,foto.id,foto.title,foto.description,foto.width,foto.height,fotos.directus_files_id.id,fotos.directus_files_id.title,fotos.directus_files_id.description,fotos.directus_files_id.width,fotos.directus_files_id.height';

export async function fetchKatten(): Promise<Kat[]> {
  return fetchDirectus<Kat[]>(
    `/items/katten?fields=${katFields}&filter[status][_eq]=actief&sort=sort`
  );
}

export async function fetchKat(slug: string): Promise<Kat> {
  const items = await fetchDirectus<Kat[]>(
    `/items/katten?fields=${katFields}&filter[slug][_eq]=${encodeURIComponent(slug)}&limit=1`
  );
  return items[0];
}

export async function fetchAlleKatten(): Promise<Kat[]> {
  return fetchDirectus<Kat[]>(
    `/items/katten?fields=${katFields}&sort=sort`
  );
}

// --- Nesten ---

const nestFields = '*,moeder.id,moeder.naam,moeder.slug,moeder.foto.id,vader.id,vader.naam,vader.slug,vader.foto.id,foto.id,foto.title,foto.description,foto.width,foto.height,fotos.directus_files_id.id,fotos.directus_files_id.title,fotos.directus_files_id.description,fotos.directus_files_id.width,fotos.directus_files_id.height,kittens.*,kittens.foto.id,kittens.foto.title';

export async function fetchNesten(): Promise<Nest[]> {
  return fetchDirectus<Nest[]>(
    `/items/nesten?fields=${nestFields}&sort=-geboortedatum`
  );
}

export async function fetchNest(slug: string): Promise<Nest> {
  const items = await fetchDirectus<Nest[]>(
    `/items/nesten?fields=${nestFields},kittens.fotos.directus_files_id.id,kittens.fotos.directus_files_id.title&filter[slug][_eq]=${encodeURIComponent(slug)}&limit=1`
  );
  return items[0];
}

// --- Kittens ---

const kittenFields = '*,foto.id,foto.title,foto.description,foto.width,foto.height,fotos.directus_files_id.id,fotos.directus_files_id.title,fotos.directus_files_id.description,fotos.directus_files_id.width,fotos.directus_files_id.height,nest.id,nest.naam,nest.slug,nest.moeder.id,nest.moeder.naam,nest.moeder.slug,nest.vader.id,nest.vader.naam,nest.vader.slug';

export async function fetchKittens(): Promise<Kitten[]> {
  return fetchDirectus<Kitten[]>(
    `/items/kittens?fields=${kittenFields}&sort=sort`
  );
}

export async function fetchKitten(slug: string): Promise<Kitten> {
  const items = await fetchDirectus<Kitten[]>(
    `/items/kittens?fields=${kittenFields}&filter[slug][_eq]=${encodeURIComponent(slug)}&limit=1`
  );
  return items[0];
}

export async function fetchBeschikbareKittens(): Promise<Kitten[]> {
  return fetchDirectus<Kitten[]>(
    `/items/kittens?fields=${kittenFields}&filter[status][_in]=beschikbaar,optie&sort=sort`
  );
}

// --- Blog ---

const blogFields = '*,afbeelding.id,afbeelding.title,afbeelding.description,afbeelding.width,afbeelding.height,fotos.directus_files_id.id,fotos.directus_files_id.title,fotos.directus_files_id.description,fotos.directus_files_id.width,fotos.directus_files_id.height';

export async function fetchBlogBerichten(): Promise<BlogBericht[]> {
  return fetchDirectus<BlogBericht[]>(
    `/items/blog_berichten?fields=${blogFields}&filter[status][_eq]=gepubliceerd&sort=-gepubliceerd_op`
  );
}

export async function fetchBlogBericht(slug: string): Promise<BlogBericht> {
  const items = await fetchDirectus<BlogBericht[]>(
    `/items/blog_berichten?fields=${blogFields}&filter[slug][_eq]=${encodeURIComponent(slug)}&limit=1`
  );
  return items[0];
}

// --- Paginas ---

export async function fetchPagina(slug: string): Promise<Pagina> {
  const items = await fetchDirectus<Pagina[]>(
    `/items/paginas?fields=*,afbeelding.id,afbeelding.title&filter[slug][_eq]=${encodeURIComponent(slug)}&limit=1`
  );
  return items[0];
}

// --- Veelgestelde Vragen ---

export async function fetchVeelgesteldeVragen(): Promise<VeelgesteldeVraag[]> {
  return fetchDirectus<VeelgesteldeVraag[]>(
    '/items/veelgestelde_vragen?filter[status][_eq]=gepubliceerd&sort=categorie,sort'
  );
}

// --- Ervaringen ---

const ervaringFields = '*,foto.id,foto.title,foto.description,foto.width,foto.height,kitten.id,kitten.naam,kitten.slug,kitten.foto.id';

export async function fetchErvaringen(): Promise<Ervaring[]> {
  return fetchDirectus<Ervaring[]>(
    `/items/ervaringen?fields=${ervaringFields}&filter[status][_eq]=gepubliceerd&sort=sort`
  );
}

// --- Site Instellingen ---

export async function fetchSiteInstellingen(): Promise<SiteInstellingen> {
  return fetchDirectus<SiteInstellingen>(
    '/items/site_instellingen?fields=*,logo.id,logo.title,hero_afbeelding.id,hero_afbeelding.title'
  );
}
