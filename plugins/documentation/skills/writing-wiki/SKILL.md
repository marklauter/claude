---
name: writing-wiki
description: Use when writing, refactoring, or reviewing a page in a software-project wiki — a GitHub wiki, docs site, or any sidebar-partitioned set of pages. Self-contained; carries its own prose discipline. Every page serves one of four readers — shopper, new user, experienced user, contributor — and that reader fixes its tone and content.
---

# Writing wiki pages

A project wiki is one document partitioned across four readers. Each page serves exactly one of them, and the reader decides everything: what the page says, how deep it goes, how it sounds. Get the reader wrong and the page fails no matter how clean the prose.

Clear pages are the residue of a clear read of the source. Comprehend the code before composing — a page written from memory drifts, and no editing recovers a wrong grasp. Read the source, read the sibling pages, then write.

## The four readers

A page picks one reader and commits. Name that reader in the lede — stated or unmistakable — so anyone who landed wrong knows to leave. A page that serves two readers is two pages.

- **Shopper — deciding whether to adopt.** Wants what the thing is, what it solves, and where it stops. Show capability and cost, never a pitch. "Indexes 10k files/sec; no incremental reindex yet" beats "blazingly fast and powerful." Name the limitation the shopper would otherwise hit on day two.
- **New user — trying to succeed once, fast.** Wants install, a quick start, the common cases. Friendly, second person, present tense, imperative steps. One task per page, in the order the reader does it. First success before first concept.
- **Experienced user — going deep.** Wants the full surface: reference, configuration, edge cases, performance. Dense, precise, lookup-oriented, exhaustive on what it covers. Assume fluency; drop the encouragement.
- **Contributor — changing the project.** Wants dev setup, architecture, the rules, how to test and submit. Direct and procedural for the steps, explanatory for the design. Names its audience in the lede so a user who wandered in leaves.

Home is the front door, not an index. One paragraph on what the project is, then route each reader to their entrance — "new here? Getting Started; evaluating? Overview; looking something up? Reference; contributing? Architecture." The sidebar enumerates pages; Home routes by reader.

## Compose the page

- **Lede first.** The first paragraph names what the page is for and which reader it serves. A reader who stops there leaves with the right impression.
- **Usage before internals.** What the reader does — the call, the config, the example — precedes what happens inside. The reader who stops at "how do I use it" still leaves with a working answer.
- **Say what is, not what isn't.** Positive assertions carry; negations gesture. "Returns the cached value" beats "does not recompute."
- **One idea per sentence; the exact word over the easy one.** Split compound sentences. Pick the precise term and reuse it verbatim — one name per concept, or retrieval scatters what should cluster.
- **Cut what the page doesn't need.** Hedges, filler, throat-clearing transitions, any sentence that restates its neighbour. Length is earned by the reader's need, not spent to look thorough.
- **Show, don't decorate.** One worked example beats a paragraph of adjectives. Strong verbs over verb-plus-adverb; concrete nouns over abstract machinery.

## Source is the accuracy authority

- **Read the source before writing about it.** Locate the clone: a `{project}.wiki/` CWD pairs with the sibling `{project}/` (strip `.wiki`); an in-repo wiki (`docs/`, a docs engine) resolves paths in-tree. Neither present and none configured → stop and ask; never write from memory.
- **Cite by symbol, never by line.** `(source: ../{project}/src/Pipeline/Builder.cs Build method)` — file plus a stable identifier. Symbols survive refactors; line numbers rot.
- **Samples compile against current source.** When a signature changes, every page that shows it is stale — fix them in the same change set.
- **Document only what exists.** No stubs, no pages for planned features. When the source drops a capability, drop its page in the same change set — a page for a deleted feature is worse than none.
- **Flag or cut the unverifiable.** A claim you cannot ground in source or a cited external spec does not ship.

## Structure and navigation

- **The sidebar is the partition.** `_Sidebar.md` declares the sections and their pages; its top groups usually map to the four readers — Overview for shoppers, Getting Started for new users, Reference for experienced, Contributing for contributors. Update it in the same change set that adds, moves, or removes a page — an unlisted page is orphaned, a dangling entry is a broken link. Past ~7 pages in a group, split it.
- **Siblings teach the pattern.** Before adding to a section, read two sibling pages end to end — lede shape, depth, where examples enter. The first page in a section sets the pattern for the next ten; invest in it, and confirm the reader with the user before writing it.
- **Reinforce, don't overlap.** Two pages on the same ground teach it twice and confuse once. Give each a different angle, example, or scope. One canonical definition per domain term — one page owns it, the rest link.
- **Cross-section links don't borrow voice.** A new-user page may summarize a concept in its own voice, then link to the deep page for the rest. Link into reference; don't paste reference into a tutorial.

## Links on a GitHub wiki

Link form follows the GitHub wiki renderer, not disk markdown — the wiki is read in the browser. Other engines resolve differently; read existing pages to confirm.

- **Page links drop `.md`:** `[text](Page-Name)`, matching the on-disk `Title-Case-With-Hyphens.md`. Including `.md` breaks the link.
- **Anchors use GitHub's slug:** lowercase, spaces and punctuation to hyphens. `## Picking a strategy` → `[text](Page-Name#picking-a-strategy)`.
- **Source links are absolute GitHub URLs:** `https://github.com/<owner>/<repo>/blob/<ref>/<path>` — a tag or SHA for `<ref>` when it must not rot. Relative `../` paths don't resolve at render time.
- **`_Sidebar.md` and `Home.md` follow the same rules** — `[Page Name](Page-Name)`, no `.md`.

## Sweep before commit

Comprehension and composition happen while writing; these run after, mechanically:

- **Read the lede alone.** Does it name the page's purpose and reader? Does it sound like that reader's voice?
- **Grep your own hedging:** `not`, `don't`, `never`, `avoid` (rewrite positive); `might`, `just`, `simply`, `basically`, `very` (cut); `will`, `would` (present tense); `e.g.`, `i.e.`, `etc.` (English); `seamless`, `powerful`, `robust`, `easy` (substance — hardest on shopper pages).
- **Grep `**` and `|---|`** — no bold, no tables outside a worked example. Headings sentence-case; identifiers and paths in backticks.
- **Verify every claim against source** once more; reconcile drift by fixing the prose.
- **Sweep the sidebar and Home** — the page is listed, in the right section; Home still routes correctly; no other page names an identifier this change renamed.

Then confirm minimally: `page saved: <Page-Name>, sidebar updated`. No recap.
