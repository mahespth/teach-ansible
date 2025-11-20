# Using “jquery” in Ansible (json_query / JMESPath)

This repository contains documentation and examples for using Ansible’s **`json_query`** filter (JMESPath) — often mis-typed as “jquery” — to work with complex data structures.

Author: **Steve Maher**  
Role: **DevOps Engineer specialising in infrastructure with Ansible**

The goal of this project is to provide a clear, practical reference that goes from:

- Basic selectors and simple examples
- Through real Ansible module outputs and facts
- To complex, deeply nested data structures that commonly trip people up

The docs are written as Markdown pages intended for:

- Viewing directly in GitHub (or GitHub Pages)
- Local browsing and editing in VS Code

---

## Structure

```text
using-jquery-for-ansible/
├─ README.md
└─ docs/
   ├─ index.md
   ├─ 01-what-is-json-query.md
   ├─ 02-basic-selectors.md
   ├─ 03-working-with-facts.md
   ├─ 04-filters-and-projections.md
   ├─ 05-quoting-and-yaml-gotchas.md
   ├─ 06-complex-real-world-examples.md
   ├─ 07-common-patterns-cheatsheet.md
   └─ 08-troubleshooting-json-query.md
```

If you enable GitHub Pages with the `docs/` folder as the source, each file becomes a web page.

---

## Publishing to GitHub Pages

- CI builds the Markdown in `docs/` into HTML using `pandoc` and deploys it to GitHub Pages.
- Workflow: `.github/workflows/pages.yml`
- Local build (optional): run `./scripts/build-docs.sh` to generate HTML into `_site/`

To publish:
1. Push to `main` (or run the workflow manually).
2. In repo settings, set **Settings → Pages → Source** to **GitHub Actions**.
3. After the workflow finishes, the Pages URL will be reported in the job summary.

---

## Viewing locally with VS Code

1. Clone or download this repository.
2. Open the folder in VS Code.
3. Use **Markdown Preview**:
   - Open any `.md` file.
   - Press `Ctrl+Shift+V` (or `Cmd+Shift+V` on macOS) to open the preview.
4. Optionally install the **“Markdown All in One”** extension for a nicer editing experience.

---

## Simple local web preview (optional)

If you want to view the docs in a browser as static files:

```bash
cd using-jquery-for-ansible
python -m http.server 8000
```

Then open `http://localhost:8000/docs/index.md` (or use a Markdown-to-HTML extension / plugin of your choice).

---

## Docs entry point

The main landing page for the documentation is:

- `docs/index.md`

From there, pages are linked in a logical learning order:

1. What is `json_query`?
2. Basic selectors
3. Working with facts and module output
4. Filters and projections
5. Quoting & YAML gotchas
6. Complex real-world examples
7. Common patterns (cheat sheet)
8. Troubleshooting `json_query`
