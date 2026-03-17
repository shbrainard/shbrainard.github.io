import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  site: 'https://scottbrainard.net',
  vite: {
    plugins: [tailwindcss()],
  },
});
