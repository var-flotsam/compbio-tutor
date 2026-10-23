# Handoff

Current state of the compbio-tutor project, kept current after each phase.

## Status
- Phase 1 (docs, prior art, data availability): done. See `docs/research.md`.
- Phase 2 (design): approved 2026-10-22, revised for Claude Code + R in all tracks.
- Phase 3 (track 1): done. Five problems (`t1-gc-content`, `t1-revcomp`,
  `t1-translate`, `t1-reading-frames`, `t1-longest-orf`) with R starter code,
  seeded per-student datasets, graders with misconception codes, hint ladders and
  explanations. 236 pytest tests pass, including R reference solutions run in R 4.3.
- Phase 4: SKILL.md and references written; headless trial passed (`evals/transcripts/trial-1.md`).
  Waiting for Ethan's own end-to-end trial before calling Phase 4 done.
- Onboarding from zero (Ethan's feedback 2026-10-23): plugin install, `tutor.py doctor`,
  `references/getting-started.md`, Python 3.9 runtime. Trial: `evals/transcripts/trial-2-setup.md`.
- Phases 5-7: not started.

## Where things are
- `plugin/skills/compbio-tutor/` is the shippable skill (inside the `plugin/` Claude Code plugin; repo root is the marketplace): `scripts/tutor.py` (CLI),
  `scripts/tutorlib/` (graders, datasets/answers, problem loader, progress),
  `problems/<id>/` (problem.toml, starter.R, explanation.md), `SKILL.md`, `references/`.
- `solutions/` holds complete R solutions, outside the skill so the tutor can't read them.
- `scripts/check_setup.R` (in the skill) checks/installs R packages; `tutor.py doctor` wraps it.
- Problems: edit `problem.toml`, then `uv run python tools/build_problems.py`.
- CI: `.github/workflows/ci.yml` (Python lint/types/tests; R solutions on 3 OSes). Not yet run on GitHub.
- Pushed to https://github.com/var-flotsam/compbio-tutor (main).

## Decisions so far
- Data: Dryad pj105 (CC0) + MPD Attie2 (copyright waived) + MGI (CC BY 4.0) + Ensembl (unrestricted).
  QTL Viewer files are not redistributed until their terms are known.
- Papers are not openly licensed: paraphrase and cite, regenerate any figures from data.
- Pilot surface: Claude Code. Students write R in all three tracks; graders stay Python (stdlib).
- Licenses: MIT (code), CC BY 4.0 (lesson text).
- Repo: var-flotsam/compbio-tutor, which Ethan creates (sessions can't create repos).
- Graders regenerate the dataset from the student's seed, so editing the data file can't change the key.
- No `renv.lock`: `doctor --install-packages` covers it; revisit for R/qtl2 in Phase 6.
- Graders must stay Python 3.9-compatible (ruff target py39 for the skill scripts; CI smoke job on 3.9).

## Open
- Ethan set a wider-network default environment; tracks 2-3 must run in a new thread to get it.
- QTL Viewer redistribution terms (not needed if Dryad + MPD suffice).
- Track 2 `t1-mouse-insulin`-style real-gene problem needs Ensembl access.

## How to trial the skill headlessly
Use `--plugin-dir <repo>/plugin`, then per turn:
`claude -p "<student message>" --session-id <uuid>` (first) / `--resume <uuid>` (later),
with `--allowedTools "Skill" "Bash(python3:*)" "Bash(Rscript:*)" "Read"`.
Without `Skill` allowed, `-p` mode denies the skill and Claude improvises a lesson.
