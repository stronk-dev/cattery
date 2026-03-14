const S = '/sounds/cat';

const SOUND_BANK: Partial<Record<string, string[]>> = {
  pet:             [`${S}/purr_short.mp3`],
  'pet-long':      [`${S}/purr.mp3`],
  'feed-crunch':   [`${S}/eat_crunch.mp3`],
  'feed-fish':     [`${S}/eat_crunch.mp3`],
  'feed-treat':    [`${S}/eat_burp.mp3`],
  'play-yarn':     [`${S}/swish.mp3`],
  'play-feather':  [`${S}/swish.mp3`],
  'play-demand':   [`${S}/demands_play.mp3`],
  groom:           [`${S}/purr_short.mp3`],
  'ask-food':      [`${S}/meow_cute.mp3`],
  'ask-attention': [`${S}/meow_cute.mp3`],
  pounce:          [`${S}/swish.mp3`],
};

// Track active audio per source file — prevent stacking same sound
const activeSounds = new Map<string, HTMLAudioElement>();

let initialized = false;

function playSound(kind: string): void {
  if (document.hidden) return;

  const sources = SOUND_BANK[kind];
  if (!sources || sources.length === 0) return;
  if (localStorage.getItem('tamagotchi_sound_muted') === '1') return;

  const src = sources[Math.floor(Math.random() * sources.length)];

  // Don't stack the same source file — stop previous if still playing
  const existing = activeSounds.get(src);
  if (existing && !existing.ended && existing.currentTime < existing.duration * 0.8) {
    return; // same sound still playing, skip
  }

  const audio = new Audio(src);
  audio.volume =
    kind === 'play-demand' || kind === 'ask-food' || kind === 'ask-attention'
      ? 0.24
      : kind === 'feed-treat'
        ? 0.36
      : kind.startsWith('feed')
        ? 0.28
        : 0.32;
  audio.play().catch(() => {});
  activeSounds.set(src, audio);

  // Clean up when done
  audio.addEventListener('ended', () => {
    if (activeSounds.get(src) === audio) activeSounds.delete(src);
  });
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
