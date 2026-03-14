/**
 * Tamagotchi game client — manages connection to game server
 * and exposes cat state to WalkingKittens + TamagotchiUI.
 *
 * Phase 2: fetch-only (no WebSocket yet).
 */

export interface TamagotchiCat {
  id: string;
  source: "katten" | "kittens";
  sourceId: number;
  slug?: string;
  name: string;
  personality: "lazy" | "playful" | "curious" | "sassy" | "shy" | "chaotic";
  furIndex: number;
  stage: "kitten" | "adult" | "elder";
  hunger: number;
  happiness: number;
  energy: number;
  cleanliness: number;
  isTamagotchi: boolean;
}

export interface CareActionLog {
  id: number;
  catId: string;
  action: string;
  visitorId: string;
  sourceType: "visitor" | "cat" | "system";
  sourceCatId?: string;
  sourceCatName?: string;
  createdAt: number;
  catName?: string;
}

export interface FamilyRelation {
  catId: string;
  relation: "mother" | "father" | "sibling";
  relatedCatId: string;
}

export interface Bond {
  catAId: string;
  catBId: string;
  affinity: number;
}

export interface GameState {
  cats: TamagotchiCat[];
  recentActions: CareActionLog[];
  family: FamilyRelation[];
  bonds: Bond[];
  trust: number;
}

type CareAction = "feed" | "pet" | "play" | "groom";
export type CareVariant =
  | "fish"
  | "pellets"
  | "treat"
  | "yarn"
  | "feather"
  | "brush";
export type CareSourceType = "visitor" | "cat" | "system";
type GameEventType =
  | "state-update"
  | "care-result"
  | "connected"
  | "disconnected";

type GameEventCallback = (data: any) => void;

class TamagotchiClient {
  private state: GameState | null = null;
  private ws: WebSocket | null = null;
  private visitorId: string;
  private listeners = new Map<GameEventType, Set<GameEventCallback>>();
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private reconnectDelay = 1000;
  private pollTimer: ReturnType<typeof setInterval> | null = null;

  constructor() {
    this.visitorId = this.getOrCreateVisitorId();
  }

  private getOrCreateVisitorId(): string {
    const key = "tamagotchi_visitor_id";
    let id = localStorage.getItem(key);
    if (!id) {
      id = crypto.randomUUID();
      localStorage.setItem(key, id);
    }
    return id;
  }

  async init(): Promise<void> {
    // Fetch initial state via HTTP
    try {
      const res = await fetch("/game/state");
      if (res.ok) {
        const data = await res.json();
        this.state = data as GameState;
        this.emit("state-update", this.state);
        this.connectWebSocket();
      } else {
        console.warn("Game server unavailable, tamagotchi disabled");
        this.startPolling();
      }
    } catch {
      console.warn("Game server unavailable, tamagotchi disabled");
      this.startPolling();
    }
  }

  private connectWebSocket(): void {
    const protocol = location.protocol === "https:" ? "wss:" : "ws:";
    const url = `${protocol}//${location.host}/ws?v=${this.visitorId}`;

    try {
      this.ws = new WebSocket(url);

      this.ws.onopen = () => {
        this.reconnectDelay = 1000;
        this.emit("connected", null);
        this.stopPolling();
      };

      this.ws.onmessage = (event) => {
        try {
          const msg = JSON.parse(event.data);
          this.handleMessage(msg);
        } catch { /* ignore bad messages */ }
      };

      this.ws.onclose = () => {
        this.ws = null;
        this.emit("disconnected", null);
        this.scheduleReconnect();
      };

      this.ws.onerror = () => {
        this.ws?.close();
      };
    } catch {
      this.scheduleReconnect();
    }
  }

  private handleMessage(msg: any): void {
    switch (msg.type) {
      case "state":
        this.state = msg as GameState;
        this.emit("state-update", this.state);
        break;
      case "tick":
        if (this.state) {
          this.state.cats = msg.cats;
          this.emit("state-update", this.state);
        }
        break;
      case "care_result":
        this.emit("care-result", msg);
        // Update local state
        if (this.state) {
          const cat = this.state.cats.find((c) => c.id === msg.catId);
          if (cat) {
            Object.assign(cat, msg.newStats);
          }
          this.state.recentActions.unshift({
            id: Date.now(),
            catId: msg.catId,
            action: msg.action,
            visitorId: "",
            sourceType: msg.sourceType || "visitor",
            sourceCatId: msg.sourceCatId,
            sourceCatName: msg.sourceCatName,
            createdAt: Math.floor(Date.now() / 1000),
            catName: msg.catName,
          });
          if (this.state.recentActions.length > 20) {
            this.state.recentActions.pop();
          }
        }
        break;
    }
  }

  private scheduleReconnect(): void {
    if (this.reconnectTimer) return;
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null;
      this.reconnectDelay = Math.min(this.reconnectDelay * 2, 30000);
      this.connectWebSocket();
    }, this.reconnectDelay);
    // Also start polling as fallback
    this.startPolling();
  }

  private startPolling(): void {
    if (this.pollTimer) return;
    this.pollTimer = setInterval(async () => {
      try {
        const res = await fetch("/game/state");
        if (res.ok) {
          const data = await res.json();
          this.state = data as GameState;
          this.emit("state-update", this.state);
        }
      } catch { /* ignore */ }
    }, 30000);
  }

  private stopPolling(): void {
    if (this.pollTimer) {
      clearInterval(this.pollTimer);
      this.pollTimer = null;
    }
  }

  sendCare(
    catId: string,
    action: CareAction,
    onScreen: string[],
    variant?: CareVariant,
    source?: { sourceType?: CareSourceType; sourceCatId?: string; sourceCatName?: string }
  ): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify({ type: "care", catId, action, onScreen, variant, ...source }));
    }
  }

  getState(): GameState | null {
    return this.state;
  }

  getTamagotchiCats(): TamagotchiCat[] {
    return this.state?.cats.filter((c) => c.isTamagotchi) || [];
  }

  getAmbientCats(): TamagotchiCat[] {
    return this.state?.cats.filter((c) => !c.isTamagotchi) || [];
  }

  getVisitorId(): string {
    return this.visitorId;
  }

  getTrust(): number {
    return this.state?.trust || 0;
  }

  on(event: GameEventType, callback: GameEventCallback): void {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set());
    }
    this.listeners.get(event)!.add(callback);
  }

  off(event: GameEventType, callback: GameEventCallback): void {
    this.listeners.get(event)?.delete(callback);
  }

  private emit(event: GameEventType, data: any): void {
    for (const cb of this.listeners.get(event) || []) {
      try { cb(data); } catch { /* ignore listener errors */ }
    }
  }
}

// Singleton instance
export const tamagotchi = new TamagotchiClient();
