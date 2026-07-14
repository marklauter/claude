---
title: Lazy accuracy depends on wiki citation hygiene
summary: A reviewer can only verify wiki claims that cite their source; uncited claims are invisible to an accuracy pass, so citation discipline is the wiki author's responsibility.
tags: [note, skills, reviewing, wiki]
created: 2026-05-25
status: evolving
---

A wiki reviewer checking claims against source can only read the source a claim cites. The coverage of an accuracy pass is therefore the intersection of source-grounded claims and claims that carry an explicit citation — a `path:symbol` reference, a code sample, a named identifier. An uncited claim like "the default timeout is 30 seconds" produces no source read and cannot be verified; it slips past unchecked.

The consequence lands on the *writing* side: every uncited claim is one the reviewer cannot defend, so citation discipline belongs to the wiki author, not the reviewer. This is the enforcement edge of writing-wiki's "source is the accuracy authority" — cite by symbol and the claim stays checkable; leave it uncited and it silently escapes review.

The eager alternative — scan the whole wiki for code references up front and build a source-file list independent of citations — buys completeness at real cost. Defer it until the citation-driven approach demonstrably misses important defects. If it does, the cheaper fix is on the writing side: flag "behavioral claim (signature, default, timeout) with no source citation" as a must-fix, closing the gap where it originates rather than compensating for it in the reader.
