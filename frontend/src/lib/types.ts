export interface DirectusFile {
  id: string;
  title: string | null;
  description: string | null;
  width: number | null;
  height: number | null;
}

export interface Kat {
  id: number;
  naam: string;
  stamboom_naam: string;
  slug: string;
  geslacht: 'poes' | 'kater';
  geboortedatum: string;
  kleur: string;
  ras: string;
  status: 'actief' | 'gepensioneerd';
  rol: 'fokpoes' | 'dekkater';
  beschrijving: string;
  gezondheid_info: string;
  foto: DirectusFile | null;
  fotos: { directus_files_id: DirectusFile }[];
  sort: number;
}

export interface Nest {
  id: number;
  naam: string;
  slug: string;
  geboortedatum: string;
  verwacht_op: string | null;
  beschrijving: string;
  status: 'verwacht' | 'geboren' | 'beschikbaar' | 'afgeleverd';
  moeder: Kat | null;
  vader: Kat | null;
  foto: DirectusFile | null;
  fotos: { directus_files_id: DirectusFile }[];
  kittens: Kitten[];
  sort: number;
}

export interface Kitten {
  id: number;
  naam: string;
  slug: string;
  geslacht: 'poes' | 'kater';
  kleur: string;
  status: 'beschikbaar' | 'optie' | 'gereserveerd' | 'verkocht';
  beschrijving: string;
  nest: Nest | null;
  foto: DirectusFile | null;
  fotos: { directus_files_id: DirectusFile }[];
  sort: number;
}

export interface BlogBericht {
  id: number;
  titel: string;
  slug: string;
  inhoud: string;
  samenvatting: string;
  afbeelding: DirectusFile | null;
  fotos: { directus_files_id: DirectusFile }[];
  status: 'concept' | 'gepubliceerd';
  gepubliceerd_op: string;
}

export interface Pagina {
  id: number;
  titel: string;
  slug: string;
  inhoud: string;
  afbeelding: DirectusFile | null;
}

export interface VeelgesteldeVraag {
  id: number;
  vraag: string;
  antwoord: string;
  categorie: 'algemeen' | 'adoptie' | 'gezondheid' | 'prijzen' | 'ras_informatie';
  status: 'concept' | 'gepubliceerd';
  sort: number;
}

export interface Ervaring {
  id: number;
  naam: string;
  tekst: string;
  foto: DirectusFile | null;
  kitten: Kitten | null;
  status: 'concept' | 'gepubliceerd';
  sort: number;
}

export interface SiteInstellingen {
  cattery_naam: string;
  ondertitel: string;
  contact_email: string;
  telefoon: string;
  adres: string;
  facebook_url: string;
  instagram_url: string;
  logo: DirectusFile | null;
  hero_afbeelding: DirectusFile | null;
}
