import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  site: 'https://shbrainard.org',
  vite: {
    plugins: [tailwindcss()],
  },
});
