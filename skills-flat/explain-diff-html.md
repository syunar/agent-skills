---
name: explain-diff-html
description: Use when the user asks for a rich explanation of a code change, diff, branch, or PR. Produces HTML output.
---

# Explain Diff

Make a rich, interactive explanation of the specified code change.

It should have these sections:

- **Background:** Explain the existing system relevant to this change. (Broadly explore surrounding code.) Include deep background for beginners (note it can be skipped), then narrow background directly relevant to the change.
- **Intuition:** Explain the core intuition for the code change. Use concrete examples with toy data. Use figures and diagrams liberally.
- **Code:** Do a high-level walkthrough of the changes to the code. Group/order the changes in an understandable way.
- **Quiz:** Five medium-difficulty multiple-choice questions testing the reader's understanding of the PR. When the user clicks, tell them whether they were correct with feedback.

## Format

- Output a single self-contained HTML file which includes CSS and JavaScript. Make the whole thing one long page with section headers and a table of contents. Don't use tabs for the top-level structure. Basic responsive styling so you can view it on a phone is nice too. Put the file in a global place outside of the code repo, and make sure the filename always starts with today's date in `YYYY-MM-DD-` format, because it helps keep the files time-sorted and out of version control. For example: `/tmp/2026-07-11-explanation-<slug>.html`
- Write with the clarity and flow of Martin Kleppmann, making it engaging and written in classic style. Transitions between sections should be smooth.
- **Diagrams:** Pick a small number of diagram families that can be reused throughout to explain various cases. Useful kinds:
  - A very simplified version of the UI that the user sees in the app, to explain UI changes.
  - A system diagram showing data flow or communication between components. Include example data.
- Don't use ASCII diagrams. Always use simple HTML designs. For code blocks, always use `<pre>` tags with `white-space: pre-wrap` or `white-space: pre`. Before saving, scan each code block's CSS and confirm it preserves whitespace.
- Use callouts for key concepts or definitions, important edge cases, etc.
