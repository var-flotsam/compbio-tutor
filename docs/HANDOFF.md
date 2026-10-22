# Handoff

Current state of the compbio-tutor project, kept current after each phase.

## Status
- Phase 1 (docs, prior art, data availability): done. See `docs/research.md`.
- Phase 2 (design): approved 2026-10-22, revised for Claude Code + R in all tracks.
- Phase 3 (track 1): done. Five problems (`t1-gc-content`, `t1-revcomp`,
  `t1-translate`, `t1-reading-frames`, `t1-longest-orf`) with R starter code,
  seeded per-student datasets, graders with misconception codes, hint ladders and
  explanations. 236 pytest tests pass, including R reference solutions run in R 4.3.
- Phase 4 (SKILL.md, try end to end with Ethan): next.
- Phases 5-7: not started.

## Where things are
- `skills/compbio-tutor/` is the shippable skill: `scripts/tutor.py` (CLI),
  `scripts/tutorlib/` (graders, datasets/answers, problem loader, progress),
  `problems/<id>/` (problem.toml, starter.R, explanation.md). No SKILL.md yet.
- `solutions/` holds complete R solutions, outside the skill so the tutor can't read them.
- `setup/check_setup.R` checks R and installs packages (`--install`).
- CI: `.github/workflows/ci.yml` (Python lint/types/tests; R solutions on 3 OSes). Not yet run on GitHub.
- Local git repo only; nothing pushed. A git bundle is copied to the project files folder after each commit.

## Decisions so far
- Data: Dryad pj105 (CC0) + MPD Attie2 (copyright waived) + MGI (CC BY 4.0) + Ensembl (unrestricted).
  QTL Viewer files are not redistributed until their terms are known.
- Papers are not openly licensed: paraphrase and cite, regenerate any figures from data.
- Pilot surface: Claude Code. Students write R in all three tracks; graders stay Python (stdlib).
- Licenses: MIT (code), CC BY 4.0 (lesson text).
- Repo: var-flotsam/compbio-tutor, which Ethan creates (sessions can't create repos).
- Graders regenerate the dataset from the student's seed, so editing the data file can't change the key.
- Deviation from design: no `renv.lock` yet; `check_setup.R --install` covers track 1. Add renv when R/qtl2 arrives (Phase 6).

## Open
- Ethan to create the GitHub repo and widen the cloud environment's network access
  (JAX, Dryad, MGI, Ensembl, CRAN, Bioconductor hosts).
- QTL Viewer redistribution terms (not needed if Dryad + MPD suffice).
- Track 2 `t1-mouse-insulin`-style real-gene problem needs Ensembl access.
