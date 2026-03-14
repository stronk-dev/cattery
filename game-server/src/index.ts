import { initDb, syncFromDirectus, getAllCats, getRecentActions, getAllFamily, getAllBonds, getVisitorTrust, touchVisitor } from "./db";
import { addClient, removeClient, send, type WSData } from "./broadcast";
import { startTickLoop } from "./tick";
import { handleCareAction } from "./actions";
import type { ClientMessage, ServerMessage } from "./types";

const PORT = parseInt(process.env.PORT || "18033");
const DB_PATH = process.env.DB_PATH || "./data/game.db";
const DIRECTUS_URL = process.env.DIRECTUS_URL || "http://directus:8055";
const ADMIN_TOKEN = process.env.GAME_ADMIN_TOKEN || "";

// Initialize database
initDb(DB_PATH);

// Sync cat roster from Directus (retry on failure since Directus may not be ready)
async function syncWithRetry(maxRetries = 10): Promise<void> {
  for (let i = 0; i < maxRetries; i++) {
    try {
      await syncFromDirectus(DIRECTUS_URL);
      return;
    } catch (err) {
      console.log(`Directus sync attempt ${i + 1}/${maxRetries} failed: ${(err as Error).message}`);
      if (i < maxRetries - 1) {
        await new Promise((r) => setTimeout(r, 3000));
      }
    }
  }
  console.warn("Could not sync from Directus — starting with existing data");
}

await syncWithRetry();

// Start stat decay loop
startTickLoop();

// Build full state message (trust is per-visitor, added in websocket open)
function getStateMessage(visitorId?: string): ServerMessage {
  return {
    type: "state",
    cats: getAllCats(),
    recentActions: getRecentActions(),
    family: getAllFamily(),
    bonds: getAllBonds(),
    trust: visitorId ? getVisitorTrust(visitorId) : 0,
  };
}

// HTTP + WebSocket server
const server = Bun.serve<WSData>({
  port: PORT,

  async fetch(req, server) {
    const url = new URL(req.url);

    // WebSocket upgrade
    if (url.pathname === "/ws") {
      const visitorId = url.searchParams.get("v") || crypto.randomUUID();
      const upgraded = server.upgrade(req, { data: { visitorId } });
      if (!upgraded) {
        return new Response("WebSocket upgrade failed", { status: 400 });
      }
      return undefined;
    }

    // REST: full game state
    if (url.pathname === "/game/state") {
      const v = url.searchParams.get("v");
      return Response.json(getStateMessage(v || undefined));
    }

    // Health check
    if (url.pathname === "/game/health") {
      return Response.json({ status: "ok", cats: getAllCats().length });
    }

    // Admin: force re-sync from Directus
    if (url.pathname === "/game/admin/sync" && req.method === "POST") {
      if (!ADMIN_TOKEN || req.headers.get("X-Game-Admin-Token") !== ADMIN_TOKEN) {
        return new Response("Unauthorized", { status: 401 });
      }
      try {
        await syncFromDirectus(DIRECTUS_URL);
        return Response.json({ status: "ok", cats: getAllCats().length });
      } catch (err) {
        return Response.json({ status: "error", message: (err as Error).message }, { status: 500 });
      }
    }

    return new Response("Not Found", { status: 404 });
  },

  websocket: {
    open(ws) {
      addClient(ws);
      touchVisitor(ws.data.visitorId);
      send(ws, getStateMessage(ws.data.visitorId));
    },

    close(ws) {
      removeClient(ws);
    },

    message(ws, raw) {
      try {
        const msg = JSON.parse(raw as string) as ClientMessage;

        if (msg.type === "care") {
          handleCareAction(
            ws,
            msg.catId,
            msg.action,
            msg.onScreen || [],
            msg.variant,
            {
              sourceType: msg.sourceType,
              sourceCatId: msg.sourceCatId,
              sourceCatName: msg.sourceCatName,
            }
          );
        }
      } catch {
        send(ws, { type: "error", message: "Invalid message" });
      }
    },
  },
});

console.log(`Game server running on port ${PORT}`);
