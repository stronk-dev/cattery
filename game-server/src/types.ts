export type Personality = "lazy" | "playful" | "curious" | "sassy" | "shy" | "chaotic";
export type Stage = "kitten" | "adult" | "elder";
export type CareAction = "feed" | "pet" | "play" | "groom" | "rest";
export type CareSourceType = "visitor" | "cat" | "system";
export type CareVariant =
  | "fish"
  | "pellets"
  | "treat"
  | "yarn"
  | "feather"
  | "brush";
export type Relation = "mother" | "father" | "sibling";

export interface CatState {
  id: string;
  source: "katten" | "kittens";
  sourceId: number;
  slug?: string;
  name: string;
  personality: Personality;
  furIndex: number;
  stage: Stage;
  hunger: number;
  happiness: number;
  energy: number;
  cleanliness: number;
  isTamagotchi: boolean;
}

export interface FamilyRelation {
  catId: string;
  relation: Relation;
  relatedCatId: string;
}

export interface CareActionLog {
  id: number;
  catId: string;
  action: CareAction;
  visitorId: string;
  sourceType: CareSourceType;
  sourceCatId?: string;
  sourceCatName?: string;
  createdAt: number;
  catName?: string;
}

export interface Bond {
  catAId: string;
  catBId: string;
  affinity: number;
}

// WebSocket messages
export type ClientMessage = {
  type: "care";
  catId: string;
  action: CareAction;
  onScreen: string[];
  variant?: CareVariant;
  sourceType?: CareSourceType;
  sourceCatId?: string;
  sourceCatName?: string;
};

export type ServerMessage =
  | {
      type: "state";
      cats: CatState[];
      recentActions: CareActionLog[];
      family: FamilyRelation[];
      bonds: Bond[];
      trust: number;
    }
  | {
      type: "care_result";
      catId: string;
      catName: string;
      action: CareAction;
      variant?: CareVariant;
      sourceType: CareSourceType;
      sourceCatId?: string;
      sourceCatName?: string;
      newStats: { hunger: number; happiness: number; energy: number; cleanliness: number };
    }
  | { type: "tick"; cats: CatState[] }
  | { type: "error"; message: string };

// Directus API response types
export interface DirectusKat {
  id: number;
  naam: string;
  slug?: string | null;
  status: "actief" | "gepensioneerd";
  persoonlijkheid?: string | null;
  vacht_index?: number | null;
}

export interface DirectusKitten {
  id: number;
  naam: string;
  slug?: string | null;
  status: "beschikbaar" | "optie" | "gereserveerd" | "verkocht";
  nest: number | null;
  persoonlijkheid?: string | null;
  vacht_index?: number | null;
}

export interface DirectusNest {
  id: number;
  naam: string;
  moeder: number | null;
  vader: number | null;
  kittens: number[];
}
