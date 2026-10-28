# Estação Raiz

**A 2D defense game prototype made in Godot — a first playable sample.**

An abandoned botanical research station still holds a heart of luminous sap. Malfunctioning machine-organisms are drawn to its energy. You defend two lanes and decide, moment to moment, **which lane receives the reinforcement from a shared energy source** — while restoring irrigation, planters and blooms between waves.

> Built by Emannuel Serrão with AI-assisted development. Original player docs in Portuguese: [README.pt-BR.md](README.pt-BR.md).

## What's in the sample

- One arena, two towers, two enemy archetypes and three waves with visual restoration between them.
- Core decision: move the shared sap boost between lanes (switching takes 0.9 s and briefly reduces damage).
- Pause / resume, how-to-play screen, new cycle with double confirmation, persistent sound and volume settings.

## Original assets

All art and audio were made for this project — no third-party assets:

- Illustrations generated from written art direction and sliced into animated parts by a script (`assets/slice_parts.py`, `assets/PROVENIENCIA.json`).
- Sound effects synthesized from code (FM / additive synthesis, deterministic noise) — provenance and hashes in `audio/*PROVENIENCIA.json`.

## Quality checks

Automated Godot test scripts cover rules, UI, save/reset, audio controls and movement (200+ assertions, all passing), plus re-opening checkpoints in a separate process. Details in [VALIDACAO.md](VALIDACAO.md) and [POLIMENTO-20261017.md](POLIMENTO-20261017.md).

## Play

Open `project.godot` in **Godot 4.4+** (Compatibility renderer) and press Play.

**Controls:** `1` / `2` or click a lane — move the reinforcement · `Space` — start/pause · `Esc` — close help / pause.

## License

All rights reserved (code, art and audio).
