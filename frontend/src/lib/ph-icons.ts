// Inline Phosphor icon SVGs for use in JS contexts (where Astro <Icon> can't be used)
// Generated from @iconify-json/ph

const S = (body: string, size = '1em') =>
  `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 256 256">${body}</svg>`;

const BODIES: Record<string, string> = {
  fish: '<path fill="currentColor" d="M168 76a12 12 0 1 1-12-12a12 12 0 0 1 12 12m48.72 67.64c-19.37 34.9-55.44 53.76-107.24 56.1l-22 51.41A8 8 0 0 1 80.1 256h-.51a8 8 0 0 1-7.19-5.78l-14.8-51.83l-51.8-14.83a8 8 0 0 1-1-15.05l51.41-22c2.35-51.78 21.21-87.84 56.09-107.22c24.75-13.74 52.74-15.84 71.88-15.18c18.64.64 36 4.27 38.86 6a8 8 0 0 1 2.83 2.83c1.69 2.85 5.33 20.21 6 38.85c.68 19.1-1.41 47.1-15.15 71.85"/>',
  'bowl-food': '<path fill="currentColor" d="M72 88V40a8 8 0 0 1 16 0v48a8 8 0 0 1-16 0m144-48v184a8 8 0 0 1-16 0v-48h-48a8 8 0 0 1-8-8a268.8 268.8 0 0 1 7.22-56.88c9.78-40.49 28.32-67.63 53.63-78.47A8 8 0 0 1 216 40m-16 13.9c-32.17 24.57-38.47 84.42-39.7 106.1H200Zm-80.11-15.21a8 8 0 1 0-15.78 2.63L112 88.63a32 32 0 0 1-64 0l7.88-47.31a8 8 0 1 0-15.78-2.63l-8 48A8 8 0 0 0 32 88a48.07 48.07 0 0 0 40 47.32V224a8 8 0 0 0 16 0v-88.68A48.07 48.07 0 0 0 128 88a8 8 0 0 0-.11-1.31Z"/>',
  cookie: '<path fill="currentColor" d="M164.49 163.51a12 12 0 1 1-17 0a12 12 0 0 1 17 0m-81-8a12 12 0 1 0 17 0a12 12 0 0 0-16.98 0Zm9-39a12 12 0 1 0-17 0a12 12 0 0 0 17-.02Zm48-1a12 12 0 1 0 0 17a12 12 0 0 0 0-17M232 128A104 104 0 1 1 128 24a8 8 0 0 1 8 8a40 40 0 0 0 40 40a8 8 0 0 1 8 8a40 40 0 0 0 40 40a8 8 0 0 1 8 8"/>',
  yarn: '<path fill="currentColor" d="M232 216h-48.61A103.95 103.95 0 1 0 128 232h104a8 8 0 1 0 0-16"/>',
  feather: '<path fill="currentColor" d="M221.28 34.75a64 64 0 0 0-90.49 0L60.69 104A15.9 15.9 0 0 0 56 115.31v73.38l-29.66 29.65a8 8 0 0 0 11.32 11.32L67.32 200h73.38a15.92 15.92 0 0 0 11.3-4.68l69.23-70a64 64 0 0 0 .05-90.57"/>',
  heart: '<path fill="currentColor" d="M178 40c-20.65 0-38.73 8.88-50 23.89C116.73 48.88 98.65 40 78 40a62.07 62.07 0 0 0-62 62c0 70 103.79 126.66 108.21 129a8 8 0 0 0 7.58 0C136.21 228.66 240 172 240 102a62.07 62.07 0 0 0-62-62"/>',
  lightning: '<path fill="currentColor" d="M215.79 118.17a8 8 0 0 0-5-5.66L153.18 90.9l14.66-73.33a8 8 0 0 0-13.69-7l-112 120a8 8 0 0 0 3 13l57.63 21.61l-14.62 73.25a8 8 0 0 0 13.69 7l112-120a8 8 0 0 0 1.94-7.26"/>',
  sparkle: '<path fill="currentColor" d="M197.58 129.06L146 110l-19-51.62a15.92 15.92 0 0 0-29.88 0L78 110l-51.62 19a15.92 15.92 0 0 0 0 29.88L78 178l19 51.62a15.92 15.92 0 0 0 29.88 0L146 178l51.62-19a15.92 15.92 0 0 0 0-29.88Z"/>',
  'speaker-high': '<path fill="currentColor" d="M155.51 24.81a8 8 0 0 0-8.42.88L77.25 80H32a16 16 0 0 0-16 16v64a16 16 0 0 0 16 16h45.25l69.84 54.31A8 8 0 0 0 160 224V32a8 8 0 0 0-4.49-7.19M32 96h40v64H32Zm112 111.64l-56-43.55V91.91l56-43.55Zm54-106.08a40 40 0 0 1 0 52.88a8 8 0 0 1-12-10.58a24 24 0 0 0 0-31.72a8 8 0 0 1 12-10.58M248 128a79.9 79.9 0 0 1-20.37 53.34a8 8 0 0 1-11.92-10.67a64 64 0 0 0 0-85.33a8 8 0 1 1 11.92-10.67A79.83 79.83 0 0 1 248 128"/>',
  'speaker-x': '<path fill="currentColor" d="M155.51 24.81a8 8 0 0 0-8.42.88L77.25 80H32a16 16 0 0 0-16 16v64a16 16 0 0 0 16 16h45.25l69.84 54.31A8 8 0 0 0 160 224V32a8 8 0 0 0-4.49-7.19M32 96h40v64H32Zm112 111.64l-56-43.55V91.91l56-43.55Zm101.66-61.3a8 8 0 0 1-11.32 11.32L216 139.31l-18.34 18.35a8 8 0 0 1-11.32-11.32L204.69 128l-18.35-18.34a8 8 0 0 1 11.32-11.32L216 116.69l18.34-18.35a8 8 0 0 1 11.32 11.32L227.31 128Z"/>',
  'fork-knife': '<path fill="currentColor" d="M72 88V40a8 8 0 0 1 16 0v48a8 8 0 0 1-16 0m-8-48v48a8 8 0 0 0 16 0V40a8 8 0 0 0-16 0m152-8a8 8 0 0 0-8 8v58.66A28 28 0 0 1 184 78V40a8 8 0 0 0-16 0v38a28 28 0 0 1-24 27.71V40a8 8 0 0 0-16 0v72a40 40 0 0 0 32 39.2V216a8 8 0 0 0 16 0v-64.8A40 40 0 0 0 208 112V40a8 8 0 0 0-8-8"/>',
};

export function phIcon(name: string, size = '1em'): string {
  const body = BODIES[name];
  if (!body) return '';
  return S(body, size);
}

// Pre-built icon strings for common sizes
export const PH = {
  fish: (s = '1em') => S(BODIES.fish, s),
  bowlFood: (s = '1em') => S(BODIES['bowl-food'], s),
  cookie: (s = '1em') => S(BODIES.cookie, s),
  yarn: (s = '1em') => S(BODIES.yarn, s),
  feather: (s = '1em') => S(BODIES.feather, s),
  heart: (s = '1em') => S(BODIES.heart, s),
  lightning: (s = '1em') => S(BODIES.lightning, s),
  sparkle: (s = '1em') => S(BODIES.sparkle, s),
  speakerHigh: (s = '1em') => S(BODIES['speaker-high'], s),
  speakerX: (s = '1em') => S(BODIES['speaker-x'], s),
  forkKnife: (s = '1em') => S(BODIES['fork-knife'], s),
};
