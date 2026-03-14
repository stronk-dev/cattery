#!/bin/bash
set -euo pipefail

# Cattery Directus Seed Script
# Populates Directus with example cats, kittens, litters, blog posts,
# pages, site settings, and stock photos.
#
# Prerequisites:
#   - Directus running with schema already set up (scripts/setup-schema.sh)
#   - Photos in scripts/seed-images/
#
# Dependencies: bash, curl, jq

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMG_DIR="$SCRIPT_DIR/seed-images"

# Load .env safely
while IFS='=' read -r key value; do
  [[ -z "$key" || "$key" =~ ^# ]] && continue
  key=$(echo "$key" | xargs)
  if [ -z "${!key+x}" ]; then
    export "$key=$value"
  fi
done < "$SCRIPT_DIR/../.env"

BASE_URL="${DIRECTUS_URL:-http://localhost:8055}"
ADMIN_EMAIL="${DIRECTUS_ADMIN_EMAIL:-admin@example.com}"
ADMIN_PASSWORD="${DIRECTUS_ADMIN_PASSWORD}"

echo "==> Connecting to Directus at $BASE_URL"

# Wait for Directus
for i in $(seq 1 30); do
  curl -sf "$BASE_URL/server/health" > /dev/null 2>&1 && break
  echo "  Waiting for Directus..."
  sleep 2
done

# Authenticate
TOKEN=$(curl -sf "$BASE_URL/auth/login" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" \
  | jq -r '.data.access_token')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "ERROR: Failed to authenticate"
  exit 1
fi
echo "==> Authenticated"

# --- Helpers ---

api() {
  local method="$1"
  local path="$2"
  local data="${3:-}"
  if [ -n "$data" ]; then
    curl -sf "$BASE_URL$path" \
      -X "$method" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d "$data"
  else
    curl -sf "$BASE_URL$path" \
      -X "$method" \
      -H "Authorization: Bearer $TOKEN"
  fi
}

# Upload a file and return its UUID
upload_file() {
  local filepath="$1"
  local title="$2"
  local filename
  filename=$(basename "$filepath")

  if [ ! -f "$filepath" ]; then
    echo "  WARNING: File not found: $filepath" >&2
    echo ""
    return
  fi

  local resp
  resp=$(curl -sf "$BASE_URL/files" \
    -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -F "title=$title" \
    -F "file=@$filepath;filename=$filename")

  echo "$resp" | jq -r '.data.id'
}

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' \
    | sed 's/[äàáâã]/a/g; s/[ëèéê]/e/g; s/[ïìíî]/i/g; s/[öòóô]/o/g; s/[üùúû]/u/g' \
    | sed 's/[^a-z0-9]/-/g' \
    | sed 's/--*/-/g; s/^-//; s/-$//'
}


# ============================================================
# UPLOAD IMAGES
# ============================================================

echo ""
echo "==> Uploading images..."

# Cats
FOTO_LUNA=$(upload_file "$IMG_DIR/katten/luna.jpg" "Luna")
FOTO_LUNA_2=$(upload_file "$IMG_DIR/katten/luna-2.jpg" "Luna op de bank")
FOTO_LUNA_3=$(upload_file "$IMG_DIR/katten/luna-3.jpg" "Luna bij het raam")
FOTO_BELLA=$(upload_file "$IMG_DIR/katten/bella.jpg" "Bella")
FOTO_OSCAR=$(upload_file "$IMG_DIR/katten/oscar.jpg" "Oscar")
FOTO_OSCAR_2=$(upload_file "$IMG_DIR/katten/oscar-2.jpg" "Oscar op de krabpaal")
FOTO_MILA=$(upload_file "$IMG_DIR/katten/mila.jpg" "Mila")
echo "  - 7 cat photos"

# Kittens
FOTO_APOLLO=$(upload_file "$IMG_DIR/kittens/apollo.jpg" "Apollo")
FOTO_APOLLO_2=$(upload_file "$IMG_DIR/kittens/apollo-2.jpg" "Apollo aan het spelen")
FOTO_ARTEMIS=$(upload_file "$IMG_DIR/kittens/artemis.jpg" "Artemis")
FOTO_ARTEMIS_2=$(upload_file "$IMG_DIR/kittens/artemis-2.jpg" "Artemis aan het slapen")
FOTO_ATLAS=$(upload_file "$IMG_DIR/kittens/atlas.jpg" "Atlas")
FOTO_AURORA=$(upload_file "$IMG_DIR/kittens/aurora.jpg" "Aurora")
FOTO_AURORA_2=$(upload_file "$IMG_DIR/kittens/aurora-2.jpg" "Aurora in een doos")
echo "  - 7 kitten photos"

# Nests
FOTO_NEST_A=$(upload_file "$IMG_DIR/nesten/a-nest.jpg" "A-nest")
FOTO_NEST_A_2=$(upload_file "$IMG_DIR/nesten/a-nest-2.jpg" "A-nest in mandje")
FOTO_NEST_A_3=$(upload_file "$IMG_DIR/nesten/a-nest-3.jpg" "A-nest bij mama")
FOTO_NEST_B=$(upload_file "$IMG_DIR/nesten/b-nest.jpg" "B-nest")
echo "  - 4 nest photos"

# Blog
FOTO_BLOG_BORN=$(upload_file "$IMG_DIR/blog/born.jpg" "Nestje geboren")
FOTO_BLOG_HEALTH=$(upload_file "$IMG_DIR/blog/health.jpg" "Gezondheid")
FOTO_BLOG_TIPS=$(upload_file "$IMG_DIR/blog/tips.jpg" "Kitten tips")
echo "  - 3 blog photos"

# Hero + Logo
FOTO_HERO=$(upload_file "$IMG_DIR/hero.jpg" "Hero achtergrond")
FOTO_LOGO=$(upload_file "$IMG_DIR/logo.png" "Cattery logo")
echo "  - 1 hero photo"
echo "  - 1 logo"


# ============================================================
# SITE INSTELLINGEN
# ============================================================

echo ""
echo "==> Updating site instellingen..."

api PATCH /items/site_instellingen "$(jq -n \
  --arg hero "$FOTO_HERO" \
  --arg logo "$FOTO_LOGO" \
  '{
    cattery_naam: "Fluffy Paws Cattery",
    ondertitel: "Britse Korthaar kittens met liefde grootgebracht",
    contact_email: "info@example.com",
    telefoon: "06-12345678",
    adres: "Voorbeeldstraat 1\n1234 AB Amsterdam",
    facebook_url: "https://facebook.com",
    instagram_url: "https://instagram.com",
    hero_afbeelding: $hero,
    logo: $logo
  }')" > /dev/null
echo "  Done"


# ============================================================
# KATTEN
# ============================================================

echo ""
echo "==> Creating cats..."

create_cat() {
  local json="$1"
  api POST /items/katten "$json" | jq -r '.data.id'
}

ID_LUNA=$(create_cat "$(jq -n --arg foto "$FOTO_LUNA" '{
  naam: "Luna",
  stamboom_naam: "Moonlight Whiskers Silver Luna",
  slug: "luna",
  geslacht: "poes",
  geboortedatum: "2021-03-15",
  kleur: "Blauw",
  ras: "Britse Korthaar",
  status: "actief",
  rol: "fokpoes",
  persoonlijkheid: "lazy",
  vacht_index: 2,
  beschrijving: "<p>Luna is onze trotse stammoeder en het hart van onze cattery. Met haar rustige karakter en prachtige blauwe vacht is zij het perfecte voorbeeld van het Britse Korthaar ras. Luna is dol op knuffelen en zoekt altijd het gezelschap van mensen op.</p><p>Zij brengt haar kalmte en lieve aard over op al haar kittens, waardoor zij uitgroeien tot fantastische huisgenoten.</p>",
  gezondheid_info: "<p><strong>HCM:</strong> Negatief (echocardiografie, 2024)<br><strong>PKD:</strong> Negatief (DNA-test)<br><strong>FIV/FeLV:</strong> Negatief<br><strong>Bloedgroep:</strong> A</p>",
  foto: $foto,
  sort: 1
}')")
echo "  - Luna (ID: $ID_LUNA)"

ID_BELLA=$(create_cat "$(jq -n --arg foto "$FOTO_BELLA" '{
  naam: "Bella",
  stamboom_naam: "Velvet Dreams Beautiful Bella",
  slug: "bella",
  geslacht: "poes",
  geboortedatum: "2022-06-20",
  kleur: "Lilac",
  ras: "Britse Korthaar",
  status: "actief",
  rol: "fokpoes",
  persoonlijkheid: "curious",
  vacht_index: 3,
  beschrijving: "<p>Bella is onze jongste fokpoes met een onweerstaanbare lilac vacht. Ze is speels, nieuwsgierig en heeft een uitgesproken persoonlijkheid. Bella houdt ervan om hoog te zitten en alles vanuit haar favoriete plekje te overzien.</p><p>Haar kittens erven haar prachtige kleur en haar avontuurlijke geest.</p>",
  gezondheid_info: "<p><strong>HCM:</strong> Negatief (echocardiografie, 2024)<br><strong>PKD:</strong> Negatief (DNA-test)<br><strong>FIV/FeLV:</strong> Negatief<br><strong>Bloedgroep:</strong> A</p>",
  foto: $foto,
  sort: 2
}')")
echo "  - Bella (ID: $ID_BELLA)"

ID_OSCAR=$(create_cat "$(jq -n --arg foto "$FOTO_OSCAR" '{
  naam: "Oscar",
  stamboom_naam: "Royal Blue Grand Oscar",
  slug: "oscar",
  geslacht: "kater",
  geboortedatum: "2020-11-08",
  kleur: "Blauw",
  ras: "Britse Korthaar",
  status: "actief",
  rol: "dekkater",
  persoonlijkheid: "lazy",
  vacht_index: 2,
  beschrijving: "<p>Oscar is onze indrukwekkende dekkater met een krachtige bouw en een fluwelen blauwe vacht. Ondanks zijn imposante verschijning is hij een echte knuffelbeer die het liefst op schoot ligt.</p><p>Als vader geeft hij zijn sterke botstructuur, brede kop en zachtaardige karakter door aan zijn nakomelingen.</p>",
  gezondheid_info: "<p><strong>HCM:</strong> Negatief (echocardiografie, 2024)<br><strong>PKD:</strong> Negatief (DNA-test)<br><strong>FIV/FeLV:</strong> Negatief<br><strong>Bloedgroep:</strong> A</p>",
  foto: $foto,
  sort: 3
}')")
echo "  - Oscar (ID: $ID_OSCAR)"

ID_MILA=$(create_cat "$(jq -n --arg foto "$FOTO_MILA" '{
  naam: "Mila",
  stamboom_naam: "Cinnamon Spice Sweet Mila",
  slug: "mila",
  geslacht: "poes",
  geboortedatum: "2019-01-12",
  kleur: "Cinnamon",
  ras: "Britse Korthaar",
  status: "gepensioneerd",
  rol: "fokpoes",
  persoonlijkheid: "sassy",
  vacht_index: 8,
  beschrijving: "<p>Mila is onze lieve gepensioneerde fokpoes. Na drie prachtige nesten geniet zij nu van haar welverdiende rust. Met haar zeldzame cinnamon kleur en haar ongelooflijk zachte karakter heeft zij een bijzondere plek in ons hart.</p><p>Mila blijft bij ons als geliefde huiskat en geniet volop van haar pensioen.</p>",
  gezondheid_info: "<p><strong>HCM:</strong> Negatief (echocardiografie, 2023)<br><strong>PKD:</strong> Negatief (DNA-test)<br><strong>FIV/FeLV:</strong> Negatief<br><strong>Bloedgroep:</strong> A</p>",
  foto: $foto,
  sort: 4
}')")
echo "  - Mila (ID: $ID_MILA)"


# ============================================================
# NESTEN
# ============================================================

echo ""
echo "==> Creating litters..."

ID_NEST_A=$(api POST /items/nesten "$(jq -n \
  --arg foto "$FOTO_NEST_A" \
  --argjson moeder "$ID_LUNA" \
  --argjson vader "$ID_OSCAR" \
  '{
    naam: "A-nest",
    slug: "a-nest",
    geboortedatum: "2025-12-10",
    status: "beschikbaar",
    moeder: $moeder,
    vader: $vader,
    beschrijving: "<p>Ons prachtige A-nest is geboren op 10 december 2025! Luna en Oscar hebben samen vier gezonde kittens gekregen. De kittens groeien voorspoedig op en zijn inmiddels klaar om hun nieuwe thuis te ontmoeten.</p><p>Alle kittens worden grootgebracht in ons gezin, zijn gewend aan huishoudelijke geluiden, kinderen en andere huisdieren.</p>",
    foto: $foto,
    sort: 1
  }')" | jq -r '.data.id')
echo "  - A-nest (ID: $ID_NEST_A)"

ID_NEST_B=$(api POST /items/nesten "$(jq -n \
  --arg foto "$FOTO_NEST_B" \
  --argjson moeder "$ID_BELLA" \
  --argjson vader "$ID_OSCAR" \
  '{
    naam: "B-nest",
    slug: "b-nest",
    verwacht_op: "2026-04-15",
    status: "verwacht",
    moeder: $moeder,
    vader: $vader,
    beschrijving: "<p>We verwachten rond half april ons B-nest! Bella en Oscar worden voor het eerst samen ouders. We kijken uit naar de geboorte van deze bijzondere kittens.</p><p>Interesse? Neem alvast contact met ons op om op de wachtlijst te komen.</p>",
    foto: $foto,
    sort: 2
  }')" | jq -r '.data.id')
echo "  - B-nest (ID: $ID_NEST_B)"


# ============================================================
# KITTENS
# ============================================================

echo ""
echo "==> Creating kittens..."

create_kitten() {
  local json="$1"
  api POST /items/kittens "$json" | jq -r '.data.id'
}

ID_APOLLO=$(create_kitten "$(jq -n \
  --arg foto "$FOTO_APOLLO" \
  --argjson nest "$ID_NEST_A" \
  '{
    naam: "Apollo",
    slug: "apollo",
    geslacht: "kater",
    kleur: "Blauw",
    status: "beschikbaar",
    persoonlijkheid: "curious",
    vacht_index: 2,
    beschrijving: "<p>Apollo is een avontuurlijke en nieuwsgierige kater. Hij is altijd de eerste die nieuwe speeltjes ontdekt en is een echte ontdekkingsreiziger. Apollo is heel sociaal en speelt graag met zijn broertjes en zusje.</p>",
    nest: $nest,
    foto: $foto,
    sort: 1
  }')")
echo "  - Apollo (ID: $ID_APOLLO)"

ID_ARTEMIS=$(create_kitten "$(jq -n \
  --arg foto "$FOTO_ARTEMIS" \
  --argjson nest "$ID_NEST_A" \
  '{
    naam: "Artemis",
    slug: "artemis",
    geslacht: "poes",
    kleur: "Lilac",
    status: "gereserveerd",
    persoonlijkheid: "lazy",
    vacht_index: 3,
    beschrijving: "<p>Artemis is een lief en rustig poesje met een prachtige lilac vacht. Ze houdt van knuffelen en spint zodra je haar optilt. Artemis is al gereserveerd door een lief gezin dat niet kan wachten om haar thuis te verwelkomen.</p>",
    nest: $nest,
    foto: $foto,
    sort: 2
  }')")
echo "  - Artemis (ID: $ID_ARTEMIS)"

ID_ATLAS=$(create_kitten "$(jq -n \
  --arg foto "$FOTO_ATLAS" \
  --argjson nest "$ID_NEST_A" \
  '{
    naam: "Atlas",
    slug: "atlas",
    geslacht: "kater",
    kleur: "Blauw",
    status: "beschikbaar",
    persoonlijkheid: "lazy",
    vacht_index: 2,
    beschrijving: "<p>Atlas is de grootste van het nest en een echte teddybeer. Hij heeft een indrukwekkende blauwe vacht en grote koperen ogen. Atlas is rustig van aard en houdt ervan om naast je op de bank te liggen.</p>",
    nest: $nest,
    foto: $foto,
    sort: 3
  }')")
echo "  - Atlas (ID: $ID_ATLAS)"

ID_AURORA=$(create_kitten "$(jq -n \
  --arg foto "$FOTO_AURORA" \
  --argjson nest "$ID_NEST_A" \
  '{
    naam: "Aurora",
    slug: "aurora",
    geslacht: "poes",
    kleur: "Blauw",
    status: "verkocht",
    persoonlijkheid: "playful",
    vacht_index: 2,
    beschrijving: "<p>Aurora is het kleinste kitten van het nest maar heeft de grootste persoonlijkheid. Ze is speels, slim en ontzettend aanhankelijk. Aurora heeft haar nieuwe thuis al gevonden bij een liefdevol gezin.</p>",
    nest: $nest,
    foto: $foto,
    sort: 4
  }')")
echo "  - Aurora (ID: $ID_AURORA)"


# ============================================================
# BLOG BERICHTEN
# ============================================================

echo ""
echo "==> Creating blog posts..."

api POST /items/blog_berichten "$(jq -n --arg foto "$FOTO_BLOG_BORN" '{
  titel: "Ons A-nest is geboren!",
  slug: "ons-a-nest-is-geboren",
  inhoud: "<p>Met grote vreugde maken wij bekend dat ons A-nest is geboren op 10 december 2025! Luna heeft vier prachtige en gezonde kittens ter wereld gebracht: drie katertjes en één poesje.</p><p>De bevalling verliep voorspoedig en alle kittens drinken goed bij mama Luna. De komende weken zullen we regelmatig updates plaatsen over hun ontwikkeling.</p><h3>De kittens</h3><ul><li><strong>Apollo</strong> — kater, blauw</li><li><strong>Artemis</strong> — poes, lilac</li><li><strong>Atlas</strong> — kater, blauw</li><li><strong>Aurora</strong> — poes, blauw</li></ul><p>Wilt u meer weten over onze kittens of heeft u interesse? Neem dan gerust <a href=\"/contact\">contact</a> met ons op!</p>",
  samenvatting: "Met grote vreugde maken wij bekend dat ons A-nest is geboren! Luna heeft vier prachtige kittens ter wereld gebracht.",
  status: "gepubliceerd",
  gepubliceerd_op: "2025-12-11T10:00:00",
  afbeelding: $foto
}')" > /dev/null
echo "  - Ons A-nest is geboren!"

api POST /items/blog_berichten "$(jq -n --arg foto "$FOTO_BLOG_HEALTH" '{
  titel: "Gezondheid bij Britse Korthaar",
  slug: "gezondheid-bij-britse-korthaar",
  inhoud: "<p>Als verantwoorde fokker staat de gezondheid van onze katten altijd voorop. In dit artikel vertellen wij meer over de gezondheidstesten die wij uitvoeren en waar u op moet letten bij het kiezen van een Britse Korthaar kitten.</p><h3>HCM Screening</h3><p>Hypertrofische cardiomyopathie (HCM) is een hartaandoening die bij katten kan voorkomen. Al onze fokkatten worden jaarlijks gescreend door middel van echocardiografie bij een gespecialiseerde dierenarts-cardioloog.</p><h3>PKD Test</h3><p>Polycystic Kidney Disease (PKD) is een erfelijke nieraandoening. Al onze katten zijn DNA-getest en vrij van PKD.</p><h3>FIV en FeLV</h3><p>Alle katten in onze cattery zijn getest op FIV (Feline Immunodeficiency Virus) en FeLV (Feline Leukemia Virus) en zijn negatief bevonden.</p><h3>Waar moet u op letten?</h3><p>Bij het kiezen van een kitten is het belangrijk om te vragen naar:</p><ul><li>Gezondheidsresultaten van beide ouders</li><li>Stamboom en registratie</li><li>Vaccinaties en ontworming</li><li>Garanties en nabegeleding</li></ul>",
  samenvatting: "Als verantwoorde fokker staat gezondheid voorop. Lees meer over onze gezondheidstesten en waar u op moet letten.",
  status: "gepubliceerd",
  gepubliceerd_op: "2025-11-05T14:00:00",
  afbeelding: $foto
}')" > /dev/null
echo "  - Gezondheid bij Britse Korthaar"

api POST /items/blog_berichten "$(jq -n --arg foto "$FOTO_BLOG_TIPS" '{
  titel: "Tips voor uw nieuwe kitten",
  slug: "tips-voor-uw-nieuwe-kitten",
  inhoud: "<p>Gefeliciteerd met uw nieuwe kitten! De eerste dagen in een nieuw huis zijn spannend voor zowel u als uw kitten. Hier zijn onze tips voor een soepele overgang.</p><h3>Voorbereiding</h3><p>Zorg dat u het volgende in huis heeft voordat uw kitten arriveert:</p><ul><li>Kattenbak met klonterende kattenbakvulling</li><li>Voer- en waterbakjes (bij voorkeur keramiek of RVS)</li><li>Krabpaal</li><li>Veilige transportbox</li><li>Speeltjes</li><li>Een rustig plekje waar het kitten zich kan terugtrekken</li></ul><h3>De eerste dagen</h3><p>Laat uw kitten rustig wennen aan de nieuwe omgeving. Begin met één kamer en breid langzaam uit. Vermijd het kitten meteen bloot te stellen aan te veel prikkels, andere huisdieren of kleine kinderen.</p><h3>Voeding</h3><p>Wij geven onze kittens premium voer. Bij vertrek krijgt u een zakje mee van het vertrouwde voer. Wilt u overstappen op een ander merk, doe dit dan geleidelijk over een week.</p><h3>Dierenarts</h3><p>Plan binnen een week na aankomst een kennismakingsbezoek bij uw eigen dierenarts. Uw kitten is volledig gevaccineerd, gechipt en ontwormd bij vertrek.</p>",
  samenvatting: "De eerste dagen met een nieuw kitten zijn spannend. Hier zijn onze tips voor voorbereiding, voeding en de eerste dagen thuis.",
  status: "gepubliceerd",
  gepubliceerd_op: "2025-10-18T09:00:00",
  afbeelding: $foto
}')" > /dev/null
echo "  - Tips voor uw nieuwe kitten"


# ============================================================
# PAGINAS
# ============================================================

echo ""
echo "==> Creating pages..."

api POST /items/paginas "$(jq -n '{
  titel: "Informatie",
  slug: "informatie",
  inhoud: "<h2>Adoptieproces</h2><p>Wij nemen de plaatsing van onze kittens zeer serieus. Hieronder leest u hoe het adoptieproces bij ons werkt, van eerste contact tot het ophalen van uw kitten.</p><h3>Stap 1: Contact opnemen</h3><p>Neem contact met ons op via het contactformulier of per e-mail. Vertel ons iets over uzelf, uw woonsituatie en uw ervaring met katten. Wij nemen binnen enkele dagen contact met u op.</p><h3>Stap 2: Kennismaking</h3><p>Bij wederzijdse interesse nodigen wij u uit voor een kennismaking bij ons thuis. U kunt dan de ouderdieren en (indien geboren) de kittens ontmoeten.</p><h3>Stap 3: Reservering</h3><p>Wanneer u een kitten wilt reserveren, vragen wij een aanbetaling van €250. Dit bedrag wordt verrekend met de totaalprijs. De reservering is definitief na ontvangst van de aanbetaling.</p><h3>Stap 4: Ophalen</h3><p>Kittens mogen vanaf 13 weken naar hun nieuwe thuis. Bij vertrek zijn zij volledig gevaccineerd, gechipt, ontwormd, voorzien van een stamboom en een startpakket.</p><h2>Prijzen</h2><p>Onze kittens kosten <strong>€950 tot €1.250</strong>, afhankelijk van kleur en geslacht. Bij de prijs is inbegrepen:</p><ul><li>Volledige vaccinaties (kattenziekte en niesziekte)</li><li>Identificatiechip met registratie</li><li>Ontworming en vlooienbehandeling</li><li>Stamboom (geregistreerd bij de rasvereniging)</li><li>Dierenarts gezondheidsverklaring</li><li>Startpakket met vertrouwd voer</li><li>Levenslang advies en begeleiding</li></ul><h2>Gezondheidsgaranties</h2><p>Wij bieden een <strong>gezondheidsgarantie van 2 jaar</strong> op erfelijke aandoeningen. Alle ouderdieren zijn getest op:</p><ul><li><strong>HCM</strong> — jaarlijkse echocardiografie door gespecialiseerde cardioloog</li><li><strong>PKD</strong> — DNA-test, alle katten negatief</li><li><strong>FIV/FeLV</strong> — getest en negatief</li></ul><p>Bij vertrek ontvangt u kopieën van alle gezondheidsresultaten van de ouderdieren.</p>"
}')" > /dev/null
echo "  - Informatie"

api POST /items/paginas "$(jq -n --arg foto "$FOTO_HERO" '{
  titel: "Over Ons",
  slug: "over-ons",
  inhoud: "<p>Welkom bij Fluffy Paws Cattery! Wij zijn een kleine, erkende cattery gevestigd in Amsterdam, gespecialiseerd in het fokken van rasechte Britse Korthaar katten.</p><h3>Ons Verhaal</h3><p>Onze passie voor Britse Korthaar katten begon meer dan tien jaar geleden toen wij onze eerste Britse Korthaar in huis haalden. Al snel waren wij betoverd door hun rustgevende aanwezigheid, zachte karakter en teddy-achtige uiterlijk.</p><p>Na jarenlange ervaring en studie zijn wij in 2019 begonnen met het fokken van deze prachtige katten. Onze cattery is kleinschalig en huiselijk — onze katten zijn geen nummers maar geliefde gezinsleden.</p><h3>Onze Visie</h3><p>Bij Fluffy Paws staat het welzijn van onze katten altijd op de eerste plaats. Wij fokken met gezonde, geteste ouderdieren en besteden veel aandacht aan de socialisatie van onze kittens. Iedere kitten groeit op in ons gezin, is gewend aan huishoudelijke geluiden, kinderen en andere huisdieren.</p><h3>Wat maakt ons bijzonder?</h3><ul><li><strong>Gezondheid voorop:</strong> Al onze fokkatten zijn getest op HCM, PKD, FIV en FeLV</li><li><strong>Kleinschalig:</strong> Maximaal twee nesten per jaar voor optimale aandacht</li><li><strong>Socialisatie:</strong> Kittens groeien op in een huiselijke omgeving</li><li><strong>Begeleiding:</strong> Levenslang advies en ondersteuning na aankoop</li><li><strong>Geregistreerd:</strong> Erkende cattery met stambomen</li></ul>",
  afbeelding: $foto
}')" > /dev/null
echo "  - Over Ons"


# ============================================================
# VEELGESTELDE VRAGEN
# ============================================================

echo ""
echo "==> Creating FAQ entries..."

api POST /items/veelgestelde_vragen '{
  "vraag": "Kan ik langskomen om de kittens te bekijken?",
  "antwoord": "<p>Ja, dat kan! Wij ontvangen potentiële adoptiegezinnen graag bij ons thuis. Neem eerst contact met ons op om een afspraak te maken. Zo kunnen wij u de tijd en aandacht geven die u verdient.</p>",
  "categorie": "algemeen",
  "status": "gepubliceerd",
  "sort": 1
}' > /dev/null
echo "  - Kan ik langskomen?"

api POST /items/veelgestelde_vragen '{
  "vraag": "Hoe oud zijn de kittens bij vertrek?",
  "antwoord": "<p>Onze kittens vertrekken op zijn vroegst op een leeftijd van <strong>13 weken</strong>. Op deze leeftijd zijn zij volledig gevaccineerd, gesocialiseerd en zelfstandig genoeg om naar hun nieuwe thuis te gaan.</p>",
  "categorie": "algemeen",
  "status": "gepubliceerd",
  "sort": 2
}' > /dev/null
echo "  - Hoe oud zijn de kittens?"

api POST /items/veelgestelde_vragen '{
  "vraag": "Hoe verloopt het reserveren van een kitten?",
  "antwoord": "<p>Na een kennismaking kunt u een kitten reserveren met een aanbetaling van €250. Bekijk onze <a href=\"/informatie\">informatiepagina</a> voor het volledige adoptieproces.</p>",
  "categorie": "adoptie",
  "status": "gepubliceerd",
  "sort": 1
}' > /dev/null
echo "  - Hoe verloopt het reserveren?"

api POST /items/veelgestelde_vragen '{
  "vraag": "Kan ik een kitten laten bezorgen?",
  "antwoord": "<p>Wij geven er de voorkeur aan dat u uw kitten persoonlijk komt ophalen. Zo kunt u kennismaken met de omgeving waarin uw kitten is opgegroeid en kunnen wij u persoonlijk overdrachtsadvies geven. In uitzonderlijke gevallen kunnen wij een bezorging bespreken.</p>",
  "categorie": "adoptie",
  "status": "gepubliceerd",
  "sort": 2
}' > /dev/null
echo "  - Kan ik een kitten laten bezorgen?"

api POST /items/veelgestelde_vragen '{
  "vraag": "Welke gezondheidsgaranties geven jullie?",
  "antwoord": "<p>Wij bieden een gezondheidsgarantie van <strong>2 jaar</strong> op erfelijke aandoeningen. Alle ouderdieren zijn getest op HCM, PKD en FIV/FeLV. Meer informatie vindt u op onze <a href=\"/informatie\">informatiepagina</a>.</p>",
  "categorie": "gezondheid",
  "status": "gepubliceerd",
  "sort": 1
}' > /dev/null
echo "  - Welke gezondheidsgaranties?"

api POST /items/veelgestelde_vragen '{
  "vraag": "Zijn de kittens gevaccineerd en gechipt?",
  "antwoord": "<p>Ja, alle kittens zijn bij vertrek volledig gevaccineerd tegen kattenziekte en niesziekte, voorzien van een identificatiechip en meerdere malen ontwormd.</p>",
  "categorie": "gezondheid",
  "status": "gepubliceerd",
  "sort": 2
}' > /dev/null
echo "  - Zijn de kittens gevaccineerd?"

api POST /items/veelgestelde_vragen '{
  "vraag": "Wat kost een kitten?",
  "antwoord": "<p>Onze kittens kosten tussen <strong>€950 en €1.250</strong>, afhankelijk van kleur en geslacht. Dit is inclusief vaccinaties, chip, stamboom, gezondheidsverklaring en een startpakket. Zie onze <a href=\"/informatie\">informatiepagina</a> voor alle details.</p>",
  "categorie": "prijzen",
  "status": "gepubliceerd",
  "sort": 1
}' > /dev/null
echo "  - Wat kost een kitten?"

api POST /items/veelgestelde_vragen '{
  "vraag": "Is de Britse Korthaar geschikt als gezinskat?",
  "antwoord": "<p>Absoluut! De Britse Korthaar staat bekend om zijn rustige, vriendelijke en geduldige karakter. Ze zijn uitstekend geschikt voor gezinnen met kinderen en kunnen goed samenleven met andere huisdieren. Het zijn geen schootkatten maar zijn graag in uw buurt.</p>",
  "categorie": "ras_informatie",
  "status": "gepubliceerd",
  "sort": 1
}' > /dev/null
echo "  - Is de BSH geschikt als gezinskat?"

api POST /items/veelgestelde_vragen '{
  "vraag": "Hoeveel verzorging heeft een Britse Korthaar nodig?",
  "antwoord": "<p>De Britse Korthaar is een relatief makkelijk ras qua verzorging. Eenmaal per week borstelen is voldoende om de vacht in goede conditie te houden. Let wel op het gewicht — het ras is aangelegd om stevig te zijn, maar overgewicht moet voorkomen worden met goed voer en voldoende beweging.</p>",
  "categorie": "ras_informatie",
  "status": "gepubliceerd",
  "sort": 2
}' > /dev/null
echo "  - Hoeveel verzorging?"


# ============================================================
# ERVARINGEN
# ============================================================

echo ""
echo "==> Creating testimonials..."

# Upload testimonial photos (reuse kitten images as "kittens in new home")
FOTO_ERV_1=$(upload_file "$IMG_DIR/kittens/aurora.jpg" "Aurora in haar nieuwe thuis")
FOTO_ERV_2=$(upload_file "$IMG_DIR/kittens/apollo.jpg" "Apollo in zijn nieuwe thuis")
echo "  - 2 testimonial photos"

api POST /items/ervaringen "$(jq -n \
  --arg foto "$FOTO_ERV_1" \
  --argjson kitten "$ID_AURORA" \
  '{
    naam: "Familie De Vries",
    tekst: "Aurora heeft zich vanaf dag één thuis gevoeld bij ons. Ze is ontzettend lief, speels en zoekt altijd het gezelschap op. De begeleiding vanuit de cattery was geweldig — we konden altijd terecht met vragen. Echt een aanrader!",
    foto: $foto,
    kitten: $kitten,
    status: "gepubliceerd",
    sort: 1
  }')" > /dev/null
echo "  - Familie De Vries"

api POST /items/ervaringen "$(jq -n \
  --arg foto "$FOTO_ERV_2" \
  '{
    naam: "Mark & Lisa",
    tekst: "Wat een fantastische ervaring om een kitten bij Fluffy Paws te adopteren. De kittens zijn duidelijk met veel liefde en aandacht grootgebracht. Onze kater is gezond, goed gesocialiseerd en een echte aanwinst voor ons gezin.",
    foto: $foto,
    status: "gepubliceerd",
    sort: 2
  }')" > /dev/null
echo "  - Mark & Lisa"

api POST /items/ervaringen '{
  "naam": "Petra Jansen",
  "tekst": "Na lang zoeken kwamen wij bij Fluffy Paws terecht en wat zijn we blij! De fokker nam uitgebreid de tijd om al onze vragen te beantwoorden en heeft ons fantastisch begeleid. Onze kitten is kerngezond en superlief.",
  "status": "gepubliceerd",
  "sort": 3
}' > /dev/null
echo "  - Petra Jansen"


# ============================================================
# GALLERY PHOTOS (M2M junction tables)
# ============================================================

echo ""
echo "==> Adding gallery photos..."

# Cats — unique gallery photos per cat
for foto in "$FOTO_LUNA_2" "$FOTO_LUNA_3"; do
  api POST /items/katten_fotos "$(jq -n --argjson kid "$ID_LUNA" --arg fid "$foto" '{katten_id: $kid, directus_files_id: $fid}')" > /dev/null
done
api POST /items/katten_fotos "$(jq -n --argjson kid "$ID_OSCAR" --arg fid "$FOTO_OSCAR_2" '{katten_id: $kid, directus_files_id: $fid}')" > /dev/null
echo "  - 3 cat gallery photos"

# Kittens — unique gallery photos per kitten
api POST /items/kittens_fotos "$(jq -n --argjson kid "$ID_APOLLO" --arg fid "$FOTO_APOLLO_2" '{kittens_id: $kid, directus_files_id: $fid}')" > /dev/null
api POST /items/kittens_fotos "$(jq -n --argjson kid "$ID_ARTEMIS" --arg fid "$FOTO_ARTEMIS_2" '{kittens_id: $kid, directus_files_id: $fid}')" > /dev/null
api POST /items/kittens_fotos "$(jq -n --argjson kid "$ID_AURORA" --arg fid "$FOTO_AURORA_2" '{kittens_id: $kid, directus_files_id: $fid}')" > /dev/null
echo "  - 3 kitten gallery photos"

# Nests — unique gallery photos
for foto in "$FOTO_NEST_A_2" "$FOTO_NEST_A_3"; do
  api POST /items/nesten_fotos "$(jq -n --argjson nid "$ID_NEST_A" --arg fid "$foto" '{nesten_id: $nid, directus_files_id: $fid}')" > /dev/null
done
echo "  - 2 nest gallery photos"

# Blog — use nest gallery photos (relevant to the birth announcement post)
for foto in "$FOTO_NEST_A_2" "$FOTO_NEST_A_3"; do
  api POST /items/blog_berichten_fotos "$(jq -n --arg fid "$foto" '{blog_berichten_id: 1, directus_files_id: $fid}')" > /dev/null
done
echo "  - 2 blog gallery photos"


# ============================================================
# DONE
# ============================================================

echo ""
echo "=== Seed complete! ==="
echo ""
echo "Created:"
echo "  - 4 cats (Luna, Bella, Oscar, Mila)"
echo "  - 2 litters (A-nest, B-nest)"
echo "  - 4 kittens (Apollo, Artemis, Atlas, Aurora)"
echo "  - 3 blog posts"
echo "  - 2 pages (Over Ons, Informatie)"
echo "  - 9 FAQ entries"
echo "  - 3 testimonials"
echo "  - 18 images uploaded"
echo "  - Site settings configured"
echo ""
echo "Visit $BASE_URL to see the admin, or build the frontend:"
echo "  cd frontend && npm run build"
