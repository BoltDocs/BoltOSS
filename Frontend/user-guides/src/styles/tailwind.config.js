/** @type {import('tailwindcss').Config} */
export default {
  theme: {
    extend: {
      typography: {
        DEFAULT: {
          css: {
            "--tw-prose-body": "currentColor",
            "--tw-prose-bullets": "var(--tw-prose-body)",
            "--tw-prose-headings": "var(--tw-prose-body)",
            "--tw-prose-links": "var(--color-link)",
            a: {
              textDecoration: "underline dotted",
              fontWeight: "inherit",
            },
            "code::before": {
              content: "none",
            },
            "code::after": {
              content: "none",
            },
            blockquote: {
              fontStyle: "normal",
            },
            "blockquote p:first-of-type::before": {
              content: "none",
            },
            "blockquote p:last-of-type::after": {
              content: "none",
            },
          },
        },
      },
    },
  },
};
