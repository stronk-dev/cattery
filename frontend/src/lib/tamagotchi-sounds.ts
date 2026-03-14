const SOUND_BANK: Partial<Record<string, string[]>> = {
  // pet: ['/sounds/tamagotchi/purr-1.ogg', '/sounds/tamagotchi/purr-2.ogg'],
  // feed: ['/sounds/tamagotchi/munch-1.ogg'],
  // play: ['/sounds/tamagotchi/chirp-1.ogg'],
  // groom: ['/sounds/tamagotchi/purr-soft.ogg'],
  // 'ask-food': ['/sounds/tamagotchi/meow-food-1.ogg'],
  // 'ask-attention': ['/sounds/tamagotchi/meow-attention-1.ogg'],
};

let initialized = false;

function playSound(kind: string): void {
  const sources = SOUND_BANK[kind];
  if (!sources || sources.length === 0) return;
  if (localStorage.getItem('tamagotchi_sound_muted') === '1') return;

  const src = sources[Math.floor(Math.random() * sources.length)];
  const audio = new Audio(src);
  audio.volume = 0.4;
  audio.play().catch(() => {});
}

export function initTamagotchiSounds(): void {
  if (initialized) return;
  initialized = true;

  document.addEventListener('tama-sound', ((e: CustomEvent) => {
    const kind = e.detail?.kind;
    if (typeof kind !== 'string' || kind.length === 0) return;
    playSound(kind);
  }) as EventListener);
}
