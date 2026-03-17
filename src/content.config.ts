import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const publications = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/publications' }),
  schema: z.object({
    title: z.string(),
    date: z.coerce.date(),
    venue: z.string(),
    link: z.string().url().optional(),
    paperurl: z.string().optional(),
    code: z.string().optional(),
    github: z.string().url().optional(),
    citation: z.string(),
  }),
});

const teaching = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/teaching' }),
  schema: z.object({
    title: z.string(),
    type: z.string().optional(),
    venue: z.string().optional(),
    date: z.coerce.date(),
    location: z.string().optional(),
  }),
});

const software = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/software' }),
  schema: z.object({
    title: z.string(),
  }),
});

export const collections = { publications, teaching, software };
