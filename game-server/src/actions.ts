import {
  getCat,
  updateCatStats,
  logCareAction,
  incrementBond,
  incrementTrust,
} from "./db";
import { broadcast, send, type WSData } from "./broadcast";
import type { CareAction, CareSourceType, CareVariant, ServerMessage } from "./types";
import type { ServerWebSocket } from "bun";

// Care action stat modifiers
const CARE_EFFECTS: Record<CareAction, { hunger: number; happiness: number; energy: number; cleanliness: number }> = {
  feed:  { hunger: 40,  happiness: 5,   energy: 5,    cleanliness: 0 },
  pet:   { hunger: 0,   happiness: 20,  energy: -5,   cleanliness: 0 },
  play:  { hunger: -10, happiness: 25,  energy: -15,  cleanliness: -5 },
  groom: { hunger: 0,   happiness: 10,  energy: 0,    cleanliness: 25 },
  rest:  { hunger: -0.5, happiness: 0.5, energy: 2,   cleanliness: 0 },
};

const CARE_VARIANTS: Partial<Record<CareAction, Record<string, { hunger: number; happiness: number; energy: number; cleanliness: number }>>> = {
  feed: {
    fish:    { hunger: 42, happiness: 6,  energy: 6,  cleanliness: 0 },
    pellets: { hunger: 28, happiness: 2,  energy: 3,  cleanliness: 0 },
    treat:   { hunger: 16, happiness: 14, energy: 8,  cleanliness: 0 },
  },
  play: {
    yarn:    { hunger: -10, happiness: 25, energy: -15, cleanliness: -5 },
    feather: { hunger: -7,  happiness: 20, energy: -11, cleanliness: -2 },
  },
  groom: {
    brush:   { hunger: 0,   happiness: 11, energy: 0,   cleanliness: 26 },
  },
};

export function handleCareAction(
  ws: ServerWebSocket<WSData>,
  catId: string,
  action: CareAction,
  onScreen: string[],
  variant?: CareVariant,
  source?: { sourceType?: CareSourceType; sourceCatId?: string; sourceCatName?: string }
): void {
  // Validate action
  if (!CARE_EFFECTS[action]) {
    send(ws, { type: "error", message: "Invalid action" });
    return;
  }

  // Check cat exists and is tamagotchi
  const cat = getCat(catId);
  if (!cat || !cat.isTamagotchi) {
    send(ws, { type: "error", message: "Cat not found or not interactive" });
    return;
  }

  const isPassive = action === "rest";
  const sourceType = source?.sourceType || "visitor";

  // Apply care effects
  const effects = CARE_VARIANTS[action]?.[variant || ""] || CARE_EFFECTS[action];
  const diminish = (current: number, delta: number): number => {
    if (delta <= 0) return Math.max(0, current + delta);
    const effective = current > 90 ? delta * 0.5 : delta;
    return Math.min(100, current + effective);
  };

  const newStats = {
    hunger: diminish(cat.hunger, effects.hunger),
    happiness: diminish(cat.happiness, effects.happiness),
    energy: diminish(cat.energy, effects.energy),
    cleanliness: diminish(cat.cleanliness, effects.cleanliness),
  };

  // Persist
  updateCatStats(catId, newStats);

  if (!isPassive) {
    if (action !== "rest") console.log(`Care: ${action} on ${cat.name} → h=${newStats.hunger.toFixed(0)} p=${newStats.happiness.toFixed(0)} e=${newStats.energy.toFixed(0)} c=${newStats.cleanliness.toFixed(0)}`);
    logCareAction(catId, action, sourceType === "visitor" ? ws.data.visitorId : "", {
      sourceType,
      sourceCatId: source?.sourceCatId,
      sourceCatName: source?.sourceCatName,
    });

    // Increment visitor trust
    if (sourceType === "visitor") {
      incrementTrust(ws.data.visitorId, action);
    }

    // Update bonds for co-present cats
    for (const otherId of onScreen) {
      if (otherId !== catId) {
        incrementBond(catId, otherId, 1);
      }
    }

    // Broadcast to all clients
    const result: ServerMessage = {
      type: "care_result",
      catId,
      catName: cat.name,
      action,
      variant,
      sourceType,
      sourceCatId: source?.sourceCatId,
      sourceCatName: source?.sourceCatName,
      newStats,
    };
    broadcast(result);
  }
}
