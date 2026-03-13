#!/bin/bash
set -euo pipefail

# Cattery Directus Schema Setup (Directus 11.x)
# Creates all collections, fields, relations, roles, policies, permissions,
# and display settings via the REST API.
#
# Note: Slugs are set by the seed script, not by Directus flows.
# Directus 11 exec operations silently fail on filter events (GH #24470).
#
# Directus 11 permissions model:
#   Role -> (linked via Access) -> Policy -> Permissions
#   Public access uses the built-in public policy (abf8a154-...)
#
# Dependencies: bash, curl, jq
# Idempotent: safe to re-run (api_quiet ignores errors on duplicates)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load .env safely (handles values with spaces)
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

# Well-known Directus 11 public policy UUID (consistent across installs)
PUBLIC_POLICY_ID="abf8a154-5b1c-4a46-ac9c-7300570f4f17"

echo "==> Connecting to Directus at $BASE_URL"

# Wait for Directus to be ready
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
  echo "ERROR: Failed to authenticate with Directus"
  exit 1
fi
echo "==> Authenticated"

# --- API helpers ---

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

api_quiet() {
  api "$@" > /dev/null 2>&1 || true
}

add_field() {
  local collection="$1"
  local data="$2"
  api_quiet POST "/fields/$collection" "$data"
}


# ============================================================
# COLLECTIONS
# ============================================================

echo "==> Creating collections..."

api_quiet POST /collections '{
  "collection": "site_instellingen",
  "meta": {
    "singleton": true,
    "icon": "settings",
    "note": "Algemene site-instellingen",
    "sort": 1,
    "translations": [{"language":"nl-NL","translation":"Site Instellingen"}]
  },
  "schema": {},
  "fields": [
    {"field": "id", "type": "integer", "schema": {"is_primary_key": true, "has_auto_increment": true}, "meta": {"hidden": true}}
  ]
}'
echo "  - site_instellingen (singleton)"

api_quiet POST /collections '{
  "collection": "katten",
  "meta": {
    "icon": "pets",
    "note": "Fokkatten van de cattery",
    "sort": 2,
    "translations": [{"language":"nl-NL","translation":"Katten"}]
  },
  "schema": {},
  "fields": [
    {"field": "id", "type": "integer", "schema": {"is_primary_key": true, "has_auto_increment": true}, "meta": {"hidden": true}}
  ]
}'
echo "  - katten"

api_quiet POST /collections '{
  "collection": "nesten",
  "meta": {
    "icon": "child_friendly",
    "note": "Nesten (worpen)",
    "sort": 3,
    "translations": [{"language":"nl-NL","translation":"Nesten"}]
  },
  "schema": {},
  "fields": [
    {"field": "id", "type": "integer", "schema": {"is_primary_key": true, "has_auto_increment": true}, "meta": {"hidden": true}}
  ]
}'
echo "  - nesten"

api_quiet POST /collections '{
  "collection": "kittens",
  "meta": {
    "icon": "cruelty_free",
    "note": "Kittens van de cattery",
    "sort": 4,
    "translations": [{"language":"nl-NL","translation":"Kittens"}]
  },
  "schema": {},
  "fields": [
    {"field": "id", "type": "integer", "schema": {"is_primary_key": true, "has_auto_increment": true}, "meta": {"hidden": true}}
  ]
}'
echo "  - kittens"

api_quiet POST /collections '{
  "collection": "blog_berichten",
  "meta": {
    "icon": "article",
    "note": "Blogberichten en nieuws",
    "sort": 5,
    "translations": [{"language":"nl-NL","translation":"Blog Berichten"}]
  },
  "schema": {},
  "fields": [
    {"field": "id", "type": "integer", "schema": {"is_primary_key": true, "has_auto_increment": true}, "meta": {"hidden": true}}
  ]
}'
echo "  - blog_berichten"

api_quiet POST /collections '{
  "collection": "paginas",
  "meta": {
    "icon": "description",
    "note": "Vrije pagina'\''s (bijv. over ons)",
    "sort": 6,
    "translations": [{"language":"nl-NL","translation":"Pagina'\''s"}]
  },
  "schema": {},
  "fields": [
    {"field": "id", "type": "integer", "schema": {"is_primary_key": true, "has_auto_increment": true}, "meta": {"hidden": true}}
  ]
}'
echo "  - paginas"

api_quiet POST /collections '{
  "collection": "veelgestelde_vragen",
  "meta": {
    "icon": "help_outline",
    "note": "Veelgestelde vragen (FAQ)",
    "sort": 7,
    "translations": [{"language":"nl-NL","translation":"Veelgestelde Vragen"}]
  },
  "schema": {},
  "fields": [
    {"field": "id", "type": "integer", "schema": {"is_primary_key": true, "has_auto_increment": true}, "meta": {"hidden": true}}
  ]
}'
echo "  - veelgestelde_vragen"

api_quiet POST /collections '{
  "collection": "ervaringen",
  "meta": {
    "icon": "favorite",
    "note": "Ervaringen van adoptiegezinnen",
    "sort": 8,
    "translations": [{"language":"nl-NL","translation":"Ervaringen"}]
  },
  "schema": {},
  "fields": [
    {"field": "id", "type": "integer", "schema": {"is_primary_key": true, "has_auto_increment": true}, "meta": {"hidden": true}}
  ]
}'
echo "  - ervaringen"

# Junction tables (hidden in admin)
for jt in katten_fotos kittens_fotos nesten_fotos blog_berichten_fotos; do
  api_quiet POST /collections "{
    \"collection\": \"$jt\",
    \"meta\": {\"icon\": \"import_export\", \"hidden\": true},
    \"schema\": {},
    \"fields\": [
      {\"field\": \"id\", \"type\": \"integer\", \"schema\": {\"is_primary_key\": true, \"has_auto_increment\": true}, \"meta\": {\"hidden\": true}}
    ]
  }"
  echo "  - $jt (junction)"
done


# ============================================================
# FIELDS
# ============================================================

echo ""
echo "==> Creating fields..."

# --- site_instellingen ---
add_field site_instellingen '{"field":"cattery_naam","type":"string","meta":{"interface":"input","display":"raw","width":"half","sort":1,"required":true,"translations":[{"language":"nl-NL","translation":"Cattery Naam"}]},"schema":{"default_value":"Mijn Cattery"}}'
add_field site_instellingen '{"field":"ondertitel","type":"string","meta":{"interface":"input","display":"raw","width":"half","sort":2,"translations":[{"language":"nl-NL","translation":"Ondertitel"}]},"schema":{}}'
add_field site_instellingen '{"field":"contact_email","type":"string","meta":{"interface":"input","display":"raw","width":"half","sort":3,"translations":[{"language":"nl-NL","translation":"Contact E-mail"}]},"schema":{}}'
add_field site_instellingen '{"field":"telefoon","type":"string","meta":{"interface":"input","display":"raw","width":"half","sort":4,"translations":[{"language":"nl-NL","translation":"Telefoon"}]},"schema":{}}'
add_field site_instellingen '{"field":"adres","type":"text","meta":{"interface":"input-multiline","display":"raw","width":"full","sort":5,"translations":[{"language":"nl-NL","translation":"Adres"}]},"schema":{}}'
add_field site_instellingen '{"field":"facebook_url","type":"string","meta":{"interface":"input","display":"raw","width":"half","sort":6,"translations":[{"language":"nl-NL","translation":"Facebook URL"}]},"schema":{}}'
add_field site_instellingen '{"field":"instagram_url","type":"string","meta":{"interface":"input","display":"raw","width":"half","sort":7,"translations":[{"language":"nl-NL","translation":"Instagram URL"}]},"schema":{}}'
add_field site_instellingen '{"field":"logo","type":"uuid","meta":{"interface":"file-image","display":"image","width":"half","sort":8,"translations":[{"language":"nl-NL","translation":"Logo"}]},"schema":{}}'
add_field site_instellingen '{"field":"hero_afbeelding","type":"uuid","meta":{"interface":"file-image","display":"image","width":"half","sort":9,"translations":[{"language":"nl-NL","translation":"Hero Afbeelding"}]},"schema":{}}'
echo "  - site_instellingen"

# --- katten ---
add_field katten '{"field":"naam","type":"string","meta":{"interface":"input","display":"raw","width":"half","sort":1,"required":true,"translations":[{"language":"nl-NL","translation":"Naam"}]},"schema":{}}'
add_field katten '{"field":"stamboom_naam","type":"string","meta":{"interface":"input","display":"raw","width":"half","sort":2,"translations":[{"language":"nl-NL","translation":"Stamboom Naam"}]},"schema":{}}'
add_field katten '{"field":"slug","type":"string","meta":{"interface":"input","display":"raw","width":"half","sort":3,"note":"URL-deel, bijv. luna of a-nest","translations":[{"language":"nl-NL","translation":"Slug"}]},"schema":{"is_unique":true}}'
add_field katten '{"field":"geslacht","type":"string","meta":{"interface":"select-dropdown","display":"labels","width":"half","sort":4,"required":true,"options":{"choices":[{"text":"Poes","value":"poes"},{"text":"Kater","value":"kater"}]},"translations":[{"language":"nl-NL","translation":"Geslacht"}]},"schema":{}}'
add_field katten '{"field":"geboortedatum","type":"date","meta":{"interface":"datetime","display":"datetime","width":"half","sort":5,"translations":[{"language":"nl-NL","translation":"Geboortedatum"}]},"schema":{}}'
add_field katten '{"field":"kleur","type":"string","meta":{"interface":"input","display":"raw","width":"half","sort":6,"translations":[{"language":"nl-NL","translation":"Kleur"}]},"schema":{}}'
add_field katten '{"field":"ras","type":"string","meta":{"interface":"input","display":"raw","width":"half","sort":7,"translations":[{"language":"nl-NL","translation":"Ras"}]},"schema":{}}'
add_field katten '{"field":"status","type":"string","meta":{"interface":"select-dropdown","display":"labels","width":"half","sort":8,"required":true,"options":{"choices":[{"text":"Actief","value":"actief"},{"text":"Gepensioneerd","value":"gepensioneerd"}]},"translations":[{"language":"nl-NL","translation":"Status"}]},"schema":{"default_value":"actief"}}'
add_field katten '{"field":"rol","type":"string","meta":{"interface":"select-dropdown","display":"labels","width":"half","sort":9,"required":true,"options":{"choices":[{"text":"Fokpoes","value":"fokpoes"},{"text":"Dekkater","value":"dekkater"}]},"translations":[{"language":"nl-NL","translation":"Rol"}]},"schema":{}}'
add_field katten '{"field":"beschrijving","type":"text","meta":{"interface":"input-rich-text-html","display":"raw","width":"full","sort":10,"translations":[{"language":"nl-NL","translation":"Beschrijving"}]},"schema":{}}'
add_field katten '{"field":"gezondheid_info","type":"text","meta":{"interface":"input-rich-text-html","display":"raw","width":"full","sort":11,"translations":[{"language":"nl-NL","translation":"Gezondheid Info"}]},"schema":{}}'
add_field katten '{"field":"foto","type":"uuid","meta":{"interface":"file-image","display":"image","width":"half","sort":12,"translations":[{"language":"nl-NL","translation":"Hoofdfoto"}]},"schema":{}}'
add_field katten '{"field":"sort","type":"integer","meta":{"interface":"input","hidden":true,"sort":14},"schema":{}}'
echo "  - katten"

# --- nesten ---
add_field nesten '{"field":"naam","type":"string","meta":{"interface":"input","display":"raw","width":"half","sort":1,"required":true,"translations":[{"language":"nl-NL","translation":"Naam"}]},"schema":{}}'
add_field nesten '{"field":"slug","type":"string","meta":{"interface":"input","display":"raw","width":"half","sort":2,"note":"URL-deel, bijv. luna of a-nest","translations":[{"language":"nl-NL","translation":"Slug"}]},"schema":{"is_unique":true}}'
add_field nesten '{"field":"geboortedatum","type":"date","meta":{"interface":"datetime","display":"datetime","width":"half","sort":3,"translations":[{"language":"nl-NL","translation":"Geboortedatum"}]},"schema":{}}'
add_field nesten '{"field":"verwacht_op","type":"date","meta":{"interface":"datetime","display":"datetime","width":"half","sort":4,"translations":[{"language":"nl-NL","translation":"Verwacht Op"}]},"schema":{}}'
add_field nesten '{"field":"beschrijving","type":"text","meta":{"interface":"input-rich-text-html","display":"raw","width":"full","sort":5,"translations":[{"language":"nl-NL","translation":"Beschrijving"}]},"schema":{}}'
add_field nesten '{"field":"status","type":"string","meta":{"interface":"select-dropdown","display":"labels","width":"half","sort":6,"required":true,"options":{"choices":[{"text":"Verwacht","value":"verwacht"},{"text":"Geboren","value":"geboren"},{"text":"Beschikbaar","value":"beschikbaar"},{"text":"Afgeleverd","value":"afgeleverd"}]},"translations":[{"language":"nl-NL","translation":"Status"}]},"schema":{"default_value":"verwacht"}}'
add_field nesten '{"field":"moeder","type":"integer","meta":{"interface":"select-dropdown-m2o","display":"related-values","width":"half","sort":7,"display_options":{"template":"{{naam}}"},"translations":[{"language":"nl-NL","translation":"Moeder"}]},"schema":{}}'
add_field nesten '{"field":"vader","type":"integer","meta":{"interface":"select-dropdown-m2o","display":"related-values","width":"half","sort":8,"display_options":{"template":"{{naam}}"},"translations":[{"language":"nl-NL","translation":"Vader"}]},"schema":{}}'
add_field nesten '{"field":"foto","type":"uuid","meta":{"interface":"file-image","display":"image","width":"half","sort":9,"translations":[{"language":"nl-NL","translation":"Foto"}]},"schema":{}}'
add_field nesten '{"field":"sort","type":"integer","meta":{"interface":"input","hidden":true,"sort":11},"schema":{}}'
echo "  - nesten"

# --- kittens ---
add_field kittens '{"field":"naam","type":"string","meta":{"interface":"input","display":"raw","width":"half","sort":1,"required":true,"translations":[{"language":"nl-NL","translation":"Naam"}]},"schema":{}}'
add_field kittens '{"field":"slug","type":"string","meta":{"interface":"input","display":"raw","width":"half","sort":2,"note":"URL-deel, bijv. luna of a-nest","translations":[{"language":"nl-NL","translation":"Slug"}]},"schema":{"is_unique":true}}'
add_field kittens '{"field":"geslacht","type":"string","meta":{"interface":"select-dropdown","display":"labels","width":"half","sort":3,"required":true,"options":{"choices":[{"text":"Poes","value":"poes"},{"text":"Kater","value":"kater"}]},"translations":[{"language":"nl-NL","translation":"Geslacht"}]},"schema":{}}'
add_field kittens '{"field":"kleur","type":"string","meta":{"interface":"input","display":"raw","width":"half","sort":4,"translations":[{"language":"nl-NL","translation":"Kleur"}]},"schema":{}}'
add_field kittens '{"field":"status","type":"string","meta":{"interface":"select-dropdown","display":"labels","width":"half","sort":5,"required":true,"options":{"choices":[{"text":"Beschikbaar","value":"beschikbaar"},{"text":"Optie","value":"optie"},{"text":"Gereserveerd","value":"gereserveerd"},{"text":"Verkocht","value":"verkocht"}]},"translations":[{"language":"nl-NL","translation":"Status"}]},"schema":{"default_value":"beschikbaar"}}'
add_field kittens '{"field":"beschrijving","type":"text","meta":{"interface":"input-rich-text-html","display":"raw","width":"full","sort":6,"translations":[{"language":"nl-NL","translation":"Beschrijving"}]},"schema":{}}'
add_field kittens '{"field":"nest","type":"integer","meta":{"interface":"select-dropdown-m2o","display":"related-values","width":"half","sort":7,"display_options":{"template":"{{naam}}"},"translations":[{"language":"nl-NL","translation":"Nest"}]},"schema":{}}'
add_field kittens '{"field":"foto","type":"uuid","meta":{"interface":"file-image","display":"image","width":"half","sort":8,"translations":[{"language":"nl-NL","translation":"Hoofdfoto"}]},"schema":{}}'
add_field kittens '{"field":"sort","type":"integer","meta":{"interface":"input","hidden":true,"sort":10},"schema":{}}'
echo "  - kittens"

# --- blog_berichten ---
add_field blog_berichten '{"field":"titel","type":"string","meta":{"interface":"input","display":"raw","width":"full","sort":1,"required":true,"translations":[{"language":"nl-NL","translation":"Titel"}]},"schema":{}}'
add_field blog_berichten '{"field":"slug","type":"string","meta":{"interface":"input","display":"raw","width":"half","sort":2,"note":"URL-deel, bijv. luna of a-nest","translations":[{"language":"nl-NL","translation":"Slug"}]},"schema":{"is_unique":true}}'
add_field blog_berichten '{"field":"inhoud","type":"text","meta":{"interface":"input-rich-text-html","display":"raw","width":"full","sort":3,"translations":[{"language":"nl-NL","translation":"Inhoud"}]},"schema":{}}'
add_field blog_berichten '{"field":"samenvatting","type":"text","meta":{"interface":"input-multiline","display":"raw","width":"full","sort":4,"translations":[{"language":"nl-NL","translation":"Samenvatting"}]},"schema":{}}'
add_field blog_berichten '{"field":"afbeelding","type":"uuid","meta":{"interface":"file-image","display":"image","width":"half","sort":5,"translations":[{"language":"nl-NL","translation":"Afbeelding"}]},"schema":{}}'
add_field blog_berichten '{"field":"status","type":"string","meta":{"interface":"select-dropdown","display":"labels","width":"half","sort":6,"required":true,"options":{"choices":[{"text":"Concept","value":"concept"},{"text":"Gepubliceerd","value":"gepubliceerd"}]},"translations":[{"language":"nl-NL","translation":"Status"}]},"schema":{"default_value":"concept"}}'
add_field blog_berichten '{"field":"gepubliceerd_op","type":"timestamp","meta":{"interface":"datetime","display":"datetime","width":"half","sort":7,"translations":[{"language":"nl-NL","translation":"Gepubliceerd Op"}]},"schema":{}}'
echo "  - blog_berichten"

# --- paginas ---
add_field paginas '{"field":"titel","type":"string","meta":{"interface":"input","display":"raw","width":"full","sort":1,"required":true,"translations":[{"language":"nl-NL","translation":"Titel"}]},"schema":{}}'
add_field paginas '{"field":"slug","type":"string","meta":{"interface":"input","display":"raw","width":"half","sort":2,"note":"URL-deel, bijv. luna of a-nest","translations":[{"language":"nl-NL","translation":"Slug"}]},"schema":{"is_unique":true}}'
add_field paginas '{"field":"inhoud","type":"text","meta":{"interface":"input-rich-text-html","display":"raw","width":"full","sort":3,"translations":[{"language":"nl-NL","translation":"Inhoud"}]},"schema":{}}'
add_field paginas '{"field":"afbeelding","type":"uuid","meta":{"interface":"file-image","display":"image","width":"half","sort":4,"translations":[{"language":"nl-NL","translation":"Afbeelding"}]},"schema":{}}'
echo "  - paginas"

# --- Junction fields ---
add_field katten_fotos '{"field":"katten_id","type":"integer","meta":{"hidden":true},"schema":{}}'
add_field katten_fotos '{"field":"directus_files_id","type":"uuid","meta":{"hidden":true},"schema":{}}'
add_field kittens_fotos '{"field":"kittens_id","type":"integer","meta":{"hidden":true},"schema":{}}'
add_field kittens_fotos '{"field":"directus_files_id","type":"uuid","meta":{"hidden":true},"schema":{}}'
add_field nesten_fotos '{"field":"nesten_id","type":"integer","meta":{"hidden":true},"schema":{}}'
add_field nesten_fotos '{"field":"directus_files_id","type":"uuid","meta":{"hidden":true},"schema":{}}'
add_field blog_berichten_fotos '{"field":"blog_berichten_id","type":"integer","meta":{"hidden":true},"schema":{}}'
add_field blog_berichten_fotos '{"field":"directus_files_id","type":"uuid","meta":{"hidden":true},"schema":{}}'

# --- veelgestelde_vragen ---
add_field veelgestelde_vragen '{"field":"vraag","type":"string","meta":{"interface":"input","display":"raw","width":"full","sort":1,"required":true,"translations":[{"language":"nl-NL","translation":"Vraag"}]},"schema":{}}'
add_field veelgestelde_vragen '{"field":"antwoord","type":"text","meta":{"interface":"input-rich-text-html","display":"raw","width":"full","sort":2,"required":true,"translations":[{"language":"nl-NL","translation":"Antwoord"}]},"schema":{}}'
add_field veelgestelde_vragen '{"field":"categorie","type":"string","meta":{"interface":"select-dropdown","display":"labels","width":"half","sort":3,"required":true,"options":{"choices":[{"text":"Algemeen","value":"algemeen"},{"text":"Adoptie","value":"adoptie"},{"text":"Gezondheid","value":"gezondheid"},{"text":"Prijzen","value":"prijzen"},{"text":"Ras Informatie","value":"ras_informatie"}]},"translations":[{"language":"nl-NL","translation":"Categorie"}]},"schema":{"default_value":"algemeen"}}'
add_field veelgestelde_vragen '{"field":"status","type":"string","meta":{"interface":"select-dropdown","display":"labels","width":"half","sort":4,"required":true,"options":{"choices":[{"text":"Concept","value":"concept"},{"text":"Gepubliceerd","value":"gepubliceerd"}]},"translations":[{"language":"nl-NL","translation":"Status"}]},"schema":{"default_value":"concept"}}'
add_field veelgestelde_vragen '{"field":"sort","type":"integer","meta":{"interface":"input","hidden":true,"sort":5},"schema":{}}'
echo "  - veelgestelde_vragen"

# --- ervaringen ---
add_field ervaringen '{"field":"naam","type":"string","meta":{"interface":"input","display":"raw","width":"half","sort":1,"required":true,"translations":[{"language":"nl-NL","translation":"Naam"}]},"schema":{}}'
add_field ervaringen '{"field":"tekst","type":"text","meta":{"interface":"input-multiline","display":"raw","width":"full","sort":2,"required":true,"translations":[{"language":"nl-NL","translation":"Tekst"}]},"schema":{}}'
add_field ervaringen '{"field":"foto","type":"uuid","meta":{"interface":"file-image","display":"image","width":"half","sort":3,"translations":[{"language":"nl-NL","translation":"Foto"}]},"schema":{}}'
add_field ervaringen '{"field":"kitten","type":"integer","meta":{"interface":"select-dropdown-m2o","display":"related-values","width":"half","sort":4,"display_options":{"template":"{{naam}}"},"translations":[{"language":"nl-NL","translation":"Kitten"}]},"schema":{}}'
add_field ervaringen '{"field":"status","type":"string","meta":{"interface":"select-dropdown","display":"labels","width":"half","sort":5,"required":true,"options":{"choices":[{"text":"Concept","value":"concept"},{"text":"Gepubliceerd","value":"gepubliceerd"}]},"translations":[{"language":"nl-NL","translation":"Status"}]},"schema":{"default_value":"concept"}}'
add_field ervaringen '{"field":"sort","type":"integer","meta":{"interface":"input","hidden":true,"sort":6},"schema":{}}'
echo "  - ervaringen"

echo "  - junction fields"


# ============================================================
# RELATIONS
# ============================================================

echo ""
echo "==> Creating relations..."

# site_instellingen.logo -> directus_files
api_quiet POST /relations '{
  "collection": "site_instellingen", "field": "logo",
  "related_collection": "directus_files",
  "meta": {"one_field": null}, "schema": {"on_delete": "SET NULL"}
}'

# site_instellingen.hero_afbeelding -> directus_files
api_quiet POST /relations '{
  "collection": "site_instellingen", "field": "hero_afbeelding",
  "related_collection": "directus_files",
  "meta": {"one_field": null}, "schema": {"on_delete": "SET NULL"}
}'

# katten.foto -> directus_files
api_quiet POST /relations '{
  "collection": "katten", "field": "foto",
  "related_collection": "directus_files",
  "meta": {"one_field": null}, "schema": {"on_delete": "SET NULL"}
}'

# katten.fotos M2M via katten_fotos
api_quiet POST /relations '{
  "collection": "katten_fotos", "field": "katten_id",
  "related_collection": "katten",
  "meta": {"one_field": "fotos", "sort_field": null, "junction_field": "directus_files_id"},
  "schema": {"on_delete": "CASCADE"}
}'
api_quiet POST /relations '{
  "collection": "katten_fotos", "field": "directus_files_id",
  "related_collection": "directus_files",
  "meta": {"one_field": null, "junction_field": "katten_id"},
  "schema": {"on_delete": "CASCADE"}
}'
add_field katten '{"field":"fotos","type":"alias","meta":{"interface":"list-m2m","display":"related-values","width":"full","sort":13,"special":["m2m"],"translations":[{"language":"nl-NL","translation":"Extra Foto'\''s"}]}}'

# nesten.moeder -> katten
api_quiet POST /relations '{
  "collection": "nesten", "field": "moeder",
  "related_collection": "katten",
  "meta": {"one_field": null}, "schema": {"on_delete": "SET NULL"}
}'

# nesten.vader -> katten
api_quiet POST /relations '{
  "collection": "nesten", "field": "vader",
  "related_collection": "katten",
  "meta": {"one_field": null}, "schema": {"on_delete": "SET NULL"}
}'

# nesten.foto -> directus_files
api_quiet POST /relations '{
  "collection": "nesten", "field": "foto",
  "related_collection": "directus_files",
  "meta": {"one_field": null}, "schema": {"on_delete": "SET NULL"}
}'

# nesten.fotos M2M via nesten_fotos
api_quiet POST /relations '{
  "collection": "nesten_fotos", "field": "nesten_id",
  "related_collection": "nesten",
  "meta": {"one_field": "fotos", "sort_field": null, "junction_field": "directus_files_id"},
  "schema": {"on_delete": "CASCADE"}
}'
api_quiet POST /relations '{
  "collection": "nesten_fotos", "field": "directus_files_id",
  "related_collection": "directus_files",
  "meta": {"one_field": null, "junction_field": "nesten_id"},
  "schema": {"on_delete": "CASCADE"}
}'
add_field nesten '{"field":"fotos","type":"alias","meta":{"interface":"list-m2m","display":"related-values","width":"full","sort":12,"special":["m2m"],"translations":[{"language":"nl-NL","translation":"Extra Foto'\''s"}]}}'

# kittens.nest -> nesten (with O2M back-reference)
api_quiet POST /relations '{
  "collection": "kittens", "field": "nest",
  "related_collection": "nesten",
  "meta": {"one_field": "kittens"}, "schema": {"on_delete": "SET NULL"}
}'
add_field nesten '{"field":"kittens","type":"alias","meta":{"interface":"list-o2m","display":"related-values","width":"full","sort":10,"special":["o2m"],"display_options":{"template":"{{naam}} ({{status}})"},"translations":[{"language":"nl-NL","translation":"Kittens"}]}}'

# kittens.foto -> directus_files
api_quiet POST /relations '{
  "collection": "kittens", "field": "foto",
  "related_collection": "directus_files",
  "meta": {"one_field": null}, "schema": {"on_delete": "SET NULL"}
}'

# kittens.fotos M2M via kittens_fotos
api_quiet POST /relations '{
  "collection": "kittens_fotos", "field": "kittens_id",
  "related_collection": "kittens",
  "meta": {"one_field": "fotos", "sort_field": null, "junction_field": "directus_files_id"},
  "schema": {"on_delete": "CASCADE"}
}'
api_quiet POST /relations '{
  "collection": "kittens_fotos", "field": "directus_files_id",
  "related_collection": "directus_files",
  "meta": {"one_field": null, "junction_field": "kittens_id"},
  "schema": {"on_delete": "CASCADE"}
}'
add_field kittens '{"field":"fotos","type":"alias","meta":{"interface":"list-m2m","display":"related-values","width":"full","sort":9,"special":["m2m"],"translations":[{"language":"nl-NL","translation":"Extra Foto'\''s"}]}}'

# blog_berichten.afbeelding -> directus_files
api_quiet POST /relations '{
  "collection": "blog_berichten", "field": "afbeelding",
  "related_collection": "directus_files",
  "meta": {"one_field": null}, "schema": {"on_delete": "SET NULL"}
}'

# blog_berichten.fotos M2M via blog_berichten_fotos
api_quiet POST /relations '{
  "collection": "blog_berichten_fotos", "field": "blog_berichten_id",
  "related_collection": "blog_berichten",
  "meta": {"one_field": "fotos", "sort_field": null, "junction_field": "directus_files_id"},
  "schema": {"on_delete": "CASCADE"}
}'
api_quiet POST /relations '{
  "collection": "blog_berichten_fotos", "field": "directus_files_id",
  "related_collection": "directus_files",
  "meta": {"one_field": null, "junction_field": "blog_berichten_id"},
  "schema": {"on_delete": "CASCADE"}
}'
add_field blog_berichten '{"field":"fotos","type":"alias","meta":{"interface":"list-m2m","display":"related-values","width":"full","sort":8,"special":["m2m"],"translations":[{"language":"nl-NL","translation":"Extra Foto'\''s"}]}}'

# paginas.afbeelding -> directus_files
api_quiet POST /relations '{
  "collection": "paginas", "field": "afbeelding",
  "related_collection": "directus_files",
  "meta": {"one_field": null}, "schema": {"on_delete": "SET NULL"}
}'

# ervaringen.foto -> directus_files
api_quiet POST /relations '{
  "collection": "ervaringen", "field": "foto",
  "related_collection": "directus_files",
  "meta": {"one_field": null}, "schema": {"on_delete": "SET NULL"}
}'

# ervaringen.kitten -> kittens
api_quiet POST /relations '{
  "collection": "ervaringen", "field": "kitten",
  "related_collection": "kittens",
  "meta": {"one_field": null}, "schema": {"on_delete": "SET NULL"}
}'

echo "  Done"


# ============================================================
# DISPLAY TEMPLATES
# ============================================================

echo ""
echo "==> Setting display templates..."

api_quiet PATCH /collections/katten '{"meta":{"display_template":"{{naam}} \u2014 {{rol}}"}}'
api_quiet PATCH /collections/nesten '{"meta":{"display_template":"{{naam}} \u2014 {{status}}"}}'
api_quiet PATCH /collections/kittens '{"meta":{"display_template":"{{naam}} \u2014 {{status}}"}}'
api_quiet PATCH /collections/blog_berichten '{"meta":{"display_template":"{{titel}}"}}'
api_quiet PATCH /collections/paginas '{"meta":{"display_template":"{{titel}}"}}'
api_quiet PATCH /collections/veelgestelde_vragen '{"meta":{"display_template":"{{vraag}}"}}'
api_quiet PATCH /collections/ervaringen '{"meta":{"display_template":"{{naam}}"}}'
echo "  Done"


# ============================================================
# BREEDER ROLE + POLICY (Directus 11 model)
# ============================================================

echo ""
echo "==> Creating Fokker (breeder) role with policy..."

# 1. Create the role
FOKKER_ROLE_ID=$(api POST /roles '{"name":"Fokker","description":"Rol voor de kattenhouder/fokker","icon":"pets"}' 2>/dev/null \
  | jq -r '.data.id // empty' 2>/dev/null || true)

if [ -z "$FOKKER_ROLE_ID" ]; then
  echo "  Role may already exist, looking up..."
  FOKKER_ROLE_ID=$(api GET /roles 2>/dev/null \
    | jq -r '.data[] | select(.name=="Fokker") | .id' 2>/dev/null || true)
fi

if [ -z "$FOKKER_ROLE_ID" ]; then
  echo "  ERROR: Could not create or find Fokker role"
else
  echo "  Role ID: $FOKKER_ROLE_ID"

  # 2. Create a policy for this role
  FOKKER_POLICY_ID=$(api POST /policies '{"name":"Fokker Beleid","icon":"pets","description":"Rechten voor de fokker","admin_access":false,"app_access":true}' 2>/dev/null \
    | jq -r '.data.id // empty' 2>/dev/null || true)

  if [ -z "$FOKKER_POLICY_ID" ]; then
    echo "  WARNING: Could not create Fokker policy"
  else
    echo "  Policy ID: $FOKKER_POLICY_ID"

    # 3. Link policy to role via access
    api_quiet POST /access "$(jq -n --arg r "$FOKKER_ROLE_ID" --arg p "$FOKKER_POLICY_ID" '{role:$r,policy:$p}')"
    echo "  Linked policy -> role"

    # 4. Create permissions on the Fokker policy
    for collection in site_instellingen katten nesten kittens blog_berichten paginas katten_fotos kittens_fotos nesten_fotos blog_berichten_fotos veelgestelde_vragen ervaringen; do
      for action in create read update delete; do
        api_quiet POST /permissions "$(jq -n --arg p "$FOKKER_POLICY_ID" --arg c "$collection" --arg a "$action" \
          '{policy:$p, collection:$c, action:$a, fields:["*"]}')"
      done
    done
    echo "  - CRUD on all cattery collections"

    # File upload permissions
    for action in create read update; do
      api_quiet POST /permissions "$(jq -n --arg p "$FOKKER_POLICY_ID" --arg a "$action" \
        '{policy:$p, collection:"directus_files", action:$a, fields:["*"]}')"
    done
    echo "  - File upload (create/read/update)"

    # Folder read
    api_quiet POST /permissions "$(jq -n --arg p "$FOKKER_POLICY_ID" \
      '{policy:$p, collection:"directus_folders", action:"read", fields:["*"]}')"
    echo "  - Folder read"
  fi
fi


# ============================================================
# PUBLIC READ PERMISSIONS (via public policy)
# ============================================================

echo ""
echo "==> Setting public read permissions..."

for collection in site_instellingen katten nesten kittens blog_berichten paginas katten_fotos kittens_fotos nesten_fotos blog_berichten_fotos veelgestelde_vragen ervaringen; do
  api_quiet POST /permissions "$(jq -n --arg p "$PUBLIC_POLICY_ID" --arg c "$collection" \
    '{policy:$p, collection:$c, action:"read", fields:["*"]}')"
done

# Public file read (needed for images via Astro build + browser)
api_quiet POST /permissions "$(jq -n --arg p "$PUBLIC_POLICY_ID" \
  '{policy:$p, collection:"directus_files", action:"read", fields:["*"]}')"
echo "  Done"


# ============================================================
# INITIALIZE SINGLETON
# ============================================================

echo ""
echo "==> Initializing site_instellingen singleton..."

api_quiet POST /items/site_instellingen '{
  "cattery_naam": "Mijn Cattery",
  "ondertitel": "Met liefde grootgebracht",
  "contact_email": "",
  "telefoon": "",
  "adres": "",
  "facebook_url": "",
  "instagram_url": ""
}'
echo "  Done"


# ============================================================
# REBUILD FLOW (webhook on content change)
# ============================================================

REBUILD_TOKEN="${REBUILD_TOKEN:-}"
if [ -n "$REBUILD_TOKEN" ]; then
  echo ""
  echo "==> Creating rebuild webhook flow..."

  # Directus in Docker reaches the host at 172.17.0.1 (Linux default bridge)
  WEBHOOK_URL="http://172.17.0.1:9000/hooks/rebuild"

  # Create the flow (idempotent — check if exists first)
  EXISTING_FLOW=$(api GET '/flows?filter[name][_eq]=Rebuild%20Website' 2>/dev/null | jq -r '.data[0].id // empty')

  if [ -z "$EXISTING_FLOW" ]; then
    FLOW_ID=$(api POST /flows "$(jq -n '{
      name: "Rebuild Website",
      status: "active",
      trigger: "event",
      accountability: "all",
      options: {
        type: "action",
        scope: ["items.create", "items.update", "items.delete"],
        collections: ["katten", "kittens", "nesten", "blog_berichten", "paginas", "site_instellingen", "veelgestelde_vragen", "ervaringen"]
      }
    }')" | jq -r '.data.id')

    # Create the webhook operation
    api_quiet POST /operations "$(jq -n --arg flow "$FLOW_ID" --arg url "$WEBHOOK_URL" --arg token "$REBUILD_TOKEN" '{
      flow: $flow,
      name: "POST to rebuild webhook",
      key: "rebuild_webhook",
      type: "request",
      position_x: 19,
      position_y: 1,
      options: {
        method: "POST",
        url: $url,
        headers: [{ header: "X-Rebuild-Token", value: $token }]
      }
    }')"

    # Set the operation as the flow's first operation
    api_quiet PATCH "/flows/$FLOW_ID" "$(jq -n --arg op "rebuild_webhook" '{operation: $op}')"

    echo "  Created flow + webhook operation"
  else
    echo "  Flow already exists (ID: $EXISTING_FLOW), skipping"
  fi
else
  echo ""
  echo "==> Skipping rebuild flow (REBUILD_TOKEN not set in .env)"
fi


# ============================================================
# SCHEMA SNAPSHOT
# ============================================================

echo ""
echo "==> Taking schema snapshot..."

mkdir -p "$SCRIPT_DIR/../directus"
api GET /schema/snapshot > "$SCRIPT_DIR/../directus/schema-snapshot.json" 2>/dev/null \
  && echo "  Saved to directus/schema-snapshot.json" \
  || echo "  WARNING: Could not take schema snapshot"


echo ""
echo "=== Schema setup complete! ==="
echo ""
echo "Next steps:"
echo "  1. Run scripts/seed.sh to populate with example data"
echo "  2. Visit $BASE_URL to verify collections in admin"
echo "  3. Run 'cd frontend && npm run build' to build the site"
