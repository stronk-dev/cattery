import type { APIRoute } from 'astro';

export const GET: APIRoute = ({ site }) => {
  const base = site?.toString().replace(/\/$/, '') || '';
  return new Response(
    `# Fluffy Paws Cattery

> Cattery gespecialiseerd in het fokken van gezonde, goed gesocialiseerde katten en kittens. Gevestigd in Nederland.

## Pagina's

- [Home](${base}/): Overzicht van de cattery, beschikbare kittens en onze fokkatten
- [Onze Katten](${base}/onze-katten): Onze fokkatten met foto's en stamboom informatie
- [Kittens](${base}/kittens): Beschikbare kittens, prijzen en reserveringen
- [Nesten](${base}/nesten): Huidige en verwachte nesten
- [Gallerij](${base}/gallerij): Foto's van al onze katten en kittens
- [Blog](${base}/blog): Nieuws, tips en informatie over katten
- [Informatie](${base}/informatie): Adoptieproces, veelgestelde vragen, gezondheidsgaranties
- [Ervaringen](${base}/ervaringen): Verhalen van blije adoptiegezinnen
- [Contact](${base}/contact): Neem contact op voor informatie of een kitten reservering
`,
    { headers: { 'Content-Type': 'text/plain; charset=utf-8' } },
  );
};
