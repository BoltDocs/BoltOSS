import { defineCollection, z } from "astro:content";
import { glob } from "astro/loaders";

const userGuides = defineCollection({
  // Load Markdown files in the `src/content/user-guides/` directory.
  loader: glob({
    base: "./src/content/user-guides",
    pattern: "**/*.md",
  }),
  // Type-check frontmatter using a schema
  schema: ({ image }) =>
    z.object({
      title: z.string(),
      description: z.string(),
      // Transform string to Date object
      pubDate: z.coerce.date(),
      updatedDate: z.coerce.date().optional(),
      heroImage: image().optional(),
      draft: z.boolean().default(false),
    }),
});

export const collections = { userGuides };
