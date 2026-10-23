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
  `evals/transcripts/trial-4-folder-boundary.md`. Ethan's aim: no permission prompts.
  The tutor reads its guides via `tutor.R guide <name>` (pre-approved Bash), not
  the Read tool; allowed-tools also covers `Rscript work/*`. Checked in a live
  multi-turn session with only `Skill` allowed: no prompts. Pre-approvals don't
  survive `claude --resume` in a new process; students re-type the slash command.
- Surfaces (2026-10-23, from current docs): works in Claude Code on the student's
  computer (terminal, desktop app Code tab, VS Code). Not in claude.ai chat (no R,
  no CRAN, no folder). Cloud sessions (web/mobile) not supported: no plugin install,
  R only via setup script + custom network allowlist, files lost unless committed;
  `doctor` flags `CLAUDE_CODE_REMOTE=true`. Phone use: Remote Control to a laptop.
  Ethan decided (2026-10-23): no cloud version.
- Seamless R (Ethan chose 2026-10-23): no PATH or settings steps for students. The
  plugin ships `plugin/bin/compbio-tutor`, which finds Rscript (PATH, then the usual
  install folders) and runs the tutor or `run work/x.R`; allowed-tools is just
  `Bash(compbio-tutor *)`. Students run code by asking the tutor, not in their own
  terminal. Live trial with only Skill allowed: no prompts. Windows to be confirmed
  by Ethan.
- Track 0, R basics (Ethan, 2026-10-23: "The tutor should also teach what you need
  to know in R in order to complete the course"): six graded problems (`r0-variables`,
  `r0-vectors`, `r0-strings`, `r0-counting`, `r0-files`, `r0-functions`) with
  per-student data. Each Track 1 problem lists its `r_basics`; `show` prints them as
  solved or not done yet, and the tutor offers an unsolved one first. Index:
  `references/track0-r-basics.md`. Data frames and plotting are still to come,
  added as R basics when tracks 2-3 are built. Version 0.4.0.
- Positron (Ethan, 2026-10-23: "Let's build it for Positron"; design:
  /mnt/project-files/compbio-tutor/designs/positron-workspace.md). Students write
  and run R in Positron with Claude Code in its side panel; the tutor reads
  `work/<id>.R` and never edits it. Ethan confirmed: grade from the script (every
  starter ends with `answer <- ...`; `grade <id> --from-script work/<id>.R` sources
  it in a fresh R via `scripts/answer_runner.R`), check only when asked, Positron
  only with the terminal as fallback, and send students in the Claude desktop app
  to Positron (`doctor`'s "Where you write R" check reads `CLAUDE_CODE_ENTRYPOINT`).
  A plugin PreToolUse hook (`plugin/hooks/guard.sh`) denies Edit/Write/Bash writes
  to `work/`, `data/` and `.compbio-tutor/` in course folders, in any permission
  mode (the extension starts in Auto). Positron's default extension gallery is
  Posit's P3M (mirrors Open VSX); the guide falls back to the Open VSX setting.
  Trial: `evals/transcripts/trial-5-positron-check.md`. Version 0.5.0.
  To verify in Ethan's Positron trial: the extension is listed by default; the
  course `.Rprofile` loads in Positron's console; whether a `POSITRON*` env var
  reaches the panel's Bash (doctor then says "Positron"); Windows.
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
with `--allowedTools "Skill"` only (the skill pre-approves `compbio-tutor`), and
`env -u CLAUDE_CODE_REMOTE` when trialling from a cloud session.
Without `Skill` allowed, `-p` mode denies the skill and Claude improvises a lesson.
