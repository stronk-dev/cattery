import { Database } from "bun:sqlite";
import type {
  CatState,
  CareActionLog,
  CareSourceType,
  FamilyRelation,
  Bond,
  Personality,
  Stage,
  DirectusKat,
  DirectusKitten,
  DirectusNest,
} from "./types";

const PERSONALITIES: Personality[] = ["lazy", "playful", "curious", "sassy", "shy", "chaotic"];
const FUR_COUNT = 10;

let db: Database;

export function initDb(path: string): Database {
  db = new Database(path, { create: true });
  db.exec("PRAGMA journal_mode=WAL");

  db.exec(`
    CREATE TABLE IF NOT EXISTS cats (
      id TEXT PRIMARY KEY,
      source TEXT NOT NULL,
      source_id INTEGER NOT NULL,
      slug TEXT,
      name TEXT NOT NULL,
      personality TEXT NOT NULL,
      fur_index INTEGER NOT NULL,
      stage TEXT NOT NULL,
      hunger REAL NOT NULL DEFAULT 75,
      happiness REAL NOT NULL DEFAULT 75,
      energy REAL NOT NULL DEFAULT 75,
      cleanliness REAL NOT NULL DEFAULT 75,
      is_tamagotchi INTEGER NOT NULL DEFAULT 1,
      last_tick_at INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS family (
      cat_id TEXT NOT NULL,
      relation TEXT NOT NULL,
      related_cat_id TEXT NOT NULL,
      PRIMARY KEY (cat_id, relation, related_cat_id)
    );

    CREATE TABLE IF NOT EXISTS bonds (
      cat_a_id TEXT NOT NULL,
      cat_b_id TEXT NOT NULL,
      affinity REAL NOT NULL DEFAULT 0,
      PRIMARY KEY (cat_a_id, cat_b_id)
    );

    CREATE TABLE IF NOT EXISTS care_actions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cat_id TEXT NOT NULL,
      action TEXT NOT NULL,
      visitor_id TEXT NOT NULL,
      source_type TEXT NOT NULL DEFAULT 'visitor',
      source_cat_id TEXT,
      source_cat_name TEXT,
      created_at INTEGER NOT NULL
    );

    CREATE INDEX IF NOT EXISTS idx_care_actions_created ON care_actions(created_at DESC);

    CREATE TABLE IF NOT EXISTS visitors (
      id TEXT PRIMARY KEY,
      trust REAL NOT NULL DEFAULT 0,
      last_seen INTEGER NOT NULL,
      first_seen INTEGER NOT NULL
    );
  `);

  ensureColumn("care_actions", "source_type", "TEXT NOT NULL DEFAULT 'visitor'");
  ensureColumn("care_actions", "source_cat_id", "TEXT");
  ensureColumn("care_actions", "source_cat_name", "TEXT");
  ensureColumn("cats", "slug", "TEXT");

  return db;
}

export function getDb(): Database {
  return db;
}

// --- Directus sync ---

function randomPersonality(): Personality {
  return PERSONALITIES[Math.floor(Math.random() * PERSONALITIES.length)];
}

function randomFurIndex(): number {
  return Math.floor(Math.random() * FUR_COUNT);
}

function katStage(status: string): Stage {
  return status === "gepensioneerd" ? "elder" : "adult";
}

function kittenIsTamagotchi(status: string): boolean {
  return status !== "verkocht";
}

export async function syncFromDirectus(directusUrl: string): Promise<void> {
  console.log("Syncing cat roster from Directus...");

  const [katten, kittens, nesten] = await Promise.all([
    fetchDirectus<DirectusKat[]>(directusUrl, "/items/katten?fields=id,naam,slug,status,persoonlijkheid,vacht_index"),
    fetchDirectus<DirectusKitten[]>(directusUrl, "/items/kittens?fields=id,naam,slug,status,nest,persoonlijkheid,vacht_index"),
    fetchDirectus<DirectusNest[]>(directusUrl, "/items/nesten?fields=id,naam,moeder,vader,kittens.id"),
  ]);

  const now = Math.floor(Date.now() / 1000);

  const upsertCat = db.prepare(`
    INSERT INTO cats (id, source, source_id, slug, name, personality, fur_index, stage, hunger, happiness, energy, cleanliness, is_tamagotchi, last_tick_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, 75, 75, 75, 75, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      slug = excluded.slug,
      name = excluded.name,
      stage = excluded.stage,
      is_tamagotchi = excluded.is_tamagotchi
  `);

  // Sync katten
  for (const kat of katten) {
    const id = `kat-${kat.id}`;
    const personality = (kat.persoonlijkheid as Personality) || randomPersonality();
    const furIndex = kat.vacht_index ?? randomFurIndex();
    const stage = katStage(kat.status);
    upsertCat.run(id, "katten", kat.id, kat.slug ?? null, kat.naam, personality, furIndex, stage, 1, now);
  }
  console.log(`  Synced ${katten.length} katten`);

  // Sync kittens
  for (const kitten of kittens) {
    const id = `kitten-${kitten.id}`;
    const personality = (kitten.persoonlijkheid as Personality) || randomPersonality();
    const furIndex = kitten.vacht_index ?? randomFurIndex();
    const isTamagotchi = kittenIsTamagotchi(kitten.status) ? 1 : 0;
    upsertCat.run(id, "kittens", kitten.id, kitten.slug ?? null, kitten.naam, personality, furIndex, "kitten", isTamagotchi, now);
  }
  console.log(`  Synced ${kittens.length} kittens`);

  // Build family relations from nesten
  db.exec("DELETE FROM family");
  const insertFamily = db.prepare(
    "INSERT OR IGNORE INTO family (cat_id, relation, related_cat_id) VALUES (?, ?, ?)"
  );

  for (const nest of nesten) {
    const kittenIds = (nest.kittens || []).map((k: any) => `kitten-${typeof k === "object" ? k.id : k}`);

    for (const kittenId of kittenIds) {
      // Parent-child relations
      if (nest.moeder) {
        insertFamily.run(kittenId, "mother", `kat-${nest.moeder}`);
        insertFamily.run(`kat-${nest.moeder}`, "mother", kittenId); // reverse lookup
      }
      if (nest.vader) {
        insertFamily.run(kittenId, "father", `kat-${nest.vader}`);
        insertFamily.run(`kat-${nest.vader}`, "father", kittenId);
      }

      // Sibling relations
      for (const siblingId of kittenIds) {
        if (siblingId !== kittenId) {
          insertFamily.run(kittenId, "sibling", siblingId);
        }
      }
    }
  }
  console.log(`  Built family relations from ${nesten.length} nesten`);
}

async function fetchDirectus<T>(baseUrl: string, path: string): Promise<T> {
  const res = await fetch(`${baseUrl}${path}`);
  if (!res.ok) {
    throw new Error(`Directus fetch failed: ${res.status} ${res.statusText} for ${path}`);
  }
  const json = await res.json();
  return json.data as T;
}

// --- Query helpers ---

export function getAllCats(): CatState[] {
  const rows = db.query("SELECT * FROM cats").all() as any[];
  return rows.map(rowToCatState);
}

export function getTamagotchiCats(): CatState[] {
  const rows = db.query("SELECT * FROM cats WHERE is_tamagotchi = 1").all() as any[];
  return rows.map(rowToCatState);
}

export function getCat(id: string): CatState | null {
  const row = db.query("SELECT * FROM cats WHERE id = ?").get(id) as any;
  return row ? rowToCatState(row) : null;
}

export function updateCatStats(
  id: string,
  stats: { hunger: number; happiness: number; energy: number; cleanliness: number }
): void {
  db.query(
    "UPDATE cats SET hunger = ?, happiness = ?, energy = ?, cleanliness = ?, last_tick_at = ? WHERE id = ?"
  ).run(stats.hunger, stats.happiness, stats.energy, stats.cleanliness, Math.floor(Date.now() / 1000), id);
}

export function getAllFamily(): FamilyRelation[] {
  const rows = db.query("SELECT * FROM family").all() as any[];
  return rows.map((r) => ({
    catId: r.cat_id,
    relation: r.relation,
    relatedCatId: r.related_cat_id,
  }));
}

export function getAllBonds(): Bond[] {
  const rows = db.query("SELECT * FROM bonds WHERE affinity > 0").all() as any[];
  return rows.map((r) => ({
    catAId: r.cat_a_id,
    catBId: r.cat_b_id,
    affinity: r.affinity,
  }));
}

export function incrementBond(catA: string, catB: string, amount: number): void {
  const [a, b] = catA < catB ? [catA, catB] : [catB, catA];
  db.query(`
    INSERT INTO bonds (cat_a_id, cat_b_id, affinity)
    VALUES (?, ?, ?)
    ON CONFLICT(cat_a_id, cat_b_id) DO UPDATE SET
      affinity = MIN(100, bonds.affinity + excluded.affinity)
  `).run(a, b, amount);
}

export function logCareAction(
  catId: string,
  action: string,
  visitorId: string,
  source: { sourceType: CareSourceType; sourceCatId?: string; sourceCatName?: string }
): void {
  db.query(
    `INSERT INTO care_actions
      (cat_id, action, visitor_id, source_type, source_cat_id, source_cat_name, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?)`
  ).run(
    catId,
    action,
    visitorId,
    source.sourceType,
    source.sourceCatId ?? null,
    source.sourceCatName ?? null,
    Math.floor(Date.now() / 1000)
  );
}

export function getRecentActions(limit = 20): CareActionLog[] {
  const rows = db
    .query(
      `SELECT ca.*, c.name as cat_name
       FROM care_actions ca
       JOIN cats c ON c.id = ca.cat_id
       ORDER BY ca.created_at DESC
       LIMIT ?`
    )
    .all(limit) as any[];
  return rows.map((r) => ({
    id: r.id,
    catId: r.cat_id,
    action: r.action,
    visitorId: r.visitor_id,
    sourceType: (r.source_type || "visitor") as CareSourceType,
    sourceCatId: r.source_cat_id || undefined,
    sourceCatName: r.source_cat_name || undefined,
    createdAt: r.created_at,
    catName: r.cat_name,
  }));
}

export function getVisitorActionsToday(visitorId: string): number {
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);
  const ts = Math.floor(startOfDay.getTime() / 1000);
  const row = db
    .query("SELECT COUNT(*) as count FROM care_actions WHERE visitor_id = ? AND created_at >= ?")
    .get(visitorId, ts) as any;
  return row?.count || 0;
}

// --- Trust system ---

const TRUST_PER_ACTION: Record<string, number> = {
  feed: 2,
  pet: 1,
  play: 3,
  groom: 1,
};

export function getVisitorTrust(visitorId: string): number {
  const now = Math.floor(Date.now() / 1000);
  const row = db.query("SELECT trust, last_seen FROM visitors WHERE id = ?").get(visitorId) as any;
  if (!row) return 0;
  // Decay: ~1 point per day of absence
  const daysSinceSeen = (now - row.last_seen) / 86400;
  return Math.max(0, row.trust - daysSinceSeen);
}

export function touchVisitor(visitorId: string): void {
  const now = Math.floor(Date.now() / 1000);
  db.query(`
    INSERT INTO visitors (id, trust, last_seen, first_seen)
    VALUES (?, 0, ?, ?)
    ON CONFLICT(id) DO UPDATE SET last_seen = ?
  `).run(visitorId, now, now, now);
}

export function incrementTrust(visitorId: string, action: string): void {
  const amount = TRUST_PER_ACTION[action] || 0;
  if (amount <= 0) return;
  const now = Math.floor(Date.now() / 1000);
  db.query(`
    INSERT INTO visitors (id, trust, last_seen, first_seen)
    VALUES (?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      trust = MIN(100, MAX(0, visitors.trust - ((? - visitors.last_seen) / 86400.0) + ?)),
      last_seen = ?
  `).run(visitorId, amount, now, now, now, amount, now);
}

function rowToCatState(row: any): CatState {
  return {
    id: row.id,
    source: row.source,
    sourceId: row.source_id,
    slug: row.slug || undefined,
    name: row.name,
    personality: row.personality,
    furIndex: row.fur_index,
    stage: row.stage,
    hunger: row.hunger,
    happiness: row.happiness,
    energy: row.energy,
    cleanliness: row.cleanliness,
    isTamagotchi: row.is_tamagotchi === 1,
  };
}
function ensureColumn(table: string, column: string, definition: string): void {
  const columns = db.query(`PRAGMA table_info(${table})`).all() as Array<{ name: string }>;
  if (!columns.some((col) => col.name === column)) {
    db.exec(`ALTER TABLE ${table} ADD COLUMN ${column} ${definition}`);
  }
}
