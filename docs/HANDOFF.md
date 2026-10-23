# Handoff

Current state of the compbio-tutor project, kept current after each phase.

## Status
- Phase 1 (docs, prior art, data availability): done. See `docs/research.md`.
- Phase 2 (design): approved 2026-10-22, revised for Claude Code + R in all tracks.
- Phase 3 (track 1): done. Five problems (`t1-gc-content`, `t1-revcomp`,
  `t1-translate`, `t1-reading-frames`, `t1-longest-orf`) with R starter code,
  seeded per-student datasets, graders with misconception codes, hint ladders and
  explanations.
- Phase 4: SKILL.md and references written; headless trial passed (`evals/transcripts/trial-1.md`).
  Waiting for Ethan's own end-to-end trial before calling Phase 4 done.
- Onboarding from zero (Ethan's feedback 2026-10-23): plugin install, `tutor.R doctor`,
  `references/getting-started.md`. Trial: `evals/transcripts/trial-2-setup.md`.
- R rewrite (Ethan, 2026-10-23: "write the answer checker in R"): the tutor command,
  graders and setup check are base R, so students install only R. Python remains
  only for repo checks (`tests/test_skill.py`) and the future eval runner.
- Course-folder rule (Ethan, 2026-10-23): nothing outside the working directory is
  read, written or changed; packages go in `.compbio-tutor/library`. Trial:
  `evals/transcripts/trial-4-folder-boundary.md`. Asked Ethan whether reading the
  skill's own installed files is OK (recommended yes).
- Phases 5-7: not started.

## Where things are
- `plugin/skills/compbio-tutor/` is the shippable skill (inside the `plugin/` Claude Code plugin; repo root is the marketplace): `scripts/tutor.R` (CLI),
  `scripts/R/` (graders, datasets/answers, problem loader, progress, doctor; base R),
  `problems/<id>/` (problem.R, starter.R, explanation.md), `SKILL.md`, `references/`.
- `solutions/` holds complete R solutions, outside the skill so the tutor can't read them.
- `tutor.R doctor [--install-packages]` checks/installs what students need.
- Problems: edit `problem.R`; datasets and answer checkers are in `scripts/R/answers.R`.
- Tests: `tests/testthat/` (graders, problems, CLI, doctor, R solutions); `tests/test_skill.py` (spec checks).
- CI: `.github/workflows/ci.yml` (skill checks, lintr, R on 3 OSes + R 4.3).
- Pushed to https://github.com/var-flotsam/compbio-tutor (main).

## Decisions so far
- Data: Dryad pj105 (CC0) + MPD Attie2 (copyright waived) + MGI (CC BY 4.0) + Ensembl (unrestricted).
  QTL Viewer files are not redistributed until their terms are known.
- Papers are not openly licensed: paraphrase and cite, regenerate any figures from data.
- Pilot surface: Claude Code. Students write R in all three tracks; the graders are base R too.
- Licenses: MIT (code), CC BY 4.0 (lesson text).
- Repo: var-flotsam/compbio-tutor, which Ethan creates (sessions can't create repos).
- Graders regenerate the dataset from the student's seed, so editing the data file can't change the key.
- No `renv.lock`: `doctor --install-packages` covers it; revisit for R/qtl2 in Phase 6.
- Only touch files inside the course folder (`course_path()` / `inside_course()` in
  `scripts/R/progress.R`); `COMPBIO_TUTOR_HOME` was removed.
- The tutor's R code must stay base R and work on R 4.3 (CI runs 4.3); only lessons use packages.

## Open
- Ethan set a wider-network default environment; tracks 2-3 must run in a new thread to get it.
- QTL Viewer redistribution terms (not needed if Dryad + MPD suffice).
- Track 2 `t1-mouse-insulin`-style real-gene problem needs Ensembl access.

## How to trial the skill headlessly
Use `--plugin-dir <repo>/plugin`, then per turn:
`claude -p "<student message>" --session-id <uuid>` (first) / `--resume <uuid>` (later),
with `--allowedTools "Skill" "Bash(Rscript:*)" "Read"`.
Without `Skill` allowed, `-p` mode denies the skill and Claude improvises a lesson.
