import { getDb, getAllCats } from "./db";
import { broadcast } from "./broadcast";
import type { Stage } from "./types";

// Decay rates per hour by stage
const DECAY_PER_HOUR: Record<Stage, number> = {
  kitten: 3,
  adult: 2,
  elder: 1,
};

const TICK_INTERVAL_MS = 30_000; // 30 seconds

export function startTickLoop(): void {
  setInterval(tick, TICK_INTERVAL_MS);
  console.log(`Tick loop started (every ${TICK_INTERVAL_MS / 1000}s)`);
}

function tick(): void {
  const db = getDb();
  const now = Math.floor(Date.now() / 1000);
  const cats = getAllCats();

  const update = db.prepare(
    "UPDATE cats SET hunger = ?, happiness = ?, energy = ?, cleanliness = ?, last_tick_at = ? WHERE id = ?"
  );

  for (const cat of cats) {
    if (!cat.isTamagotchi) continue;

    const row = db.query("SELECT last_tick_at FROM cats WHERE id = ?").get(cat.id) as any;
    const lastTick = row?.last_tick_at || now;
    const elapsed = Math.max(0, now - lastTick);
    if (elapsed === 0) continue;

    const rate = DECAY_PER_HOUR[cat.stage];
    const decay = rate * (elapsed / 3600);

    const hunger = Math.max(0, cat.hunger - decay);
    const happiness = Math.max(0, cat.happiness - decay);
    const energy = Math.max(0, cat.energy - decay);
    const cleanliness = Math.max(0, cat.cleanliness - decay);

    update.run(hunger, happiness, energy, cleanliness, now, cat.id);
  }

  const updatedCats = getAllCats();
  broadcast({ type: "tick", cats: updatedCats });
}
