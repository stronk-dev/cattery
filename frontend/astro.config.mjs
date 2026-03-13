// @ts-check
import { defineConfig } from 'astro/config';
import { loadEnv } from 'vite';
import sitemap from '@astrojs/sitemap';

const env = loadEnv(process.env.NODE_ENV || 'production', '..', '');

// https://astro.build/config
export default defineConfig({
  output: 'static',
  site: env.SITE_URL || 'http://localhost:4321',
  integrations: [sitemap()],
  vite: {
    envDir: '..',
  },
});
