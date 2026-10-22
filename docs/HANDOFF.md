# Handoff

Current state of the compbio-tutor project, kept current after each phase.

## Status
- Phase 1 (docs, prior art, data availability): done. See `docs/research.md`.
- Phase 2 (design): approved 2026-10-22, revised for Claude Code + R. Open: R in all tracks or track 3 only.
- Phases 3-7: not started.

## Where things are
- Local git repo only; nothing pushed. Ethan has not yet picked a GitHub repo.
- A copy of the repo (git bundle) is kept in the project files folder after each commit.

## Decisions so far
- Data: Dryad pj105 (CC0) + MPD Attie2 (copyright waived) + MGI (CC BY 4.0) + Ensembl (unrestricted).
  QTL Viewer files are not redistributed until their terms are known.
- Papers are not openly licensed: paraphrase and cite, regenerate any figures from data.

- Pilot surface: Claude Code. Students write R; graders stay Python (stdlib).
- Licenses: MIT (code), CC BY 4.0 (lesson text).
- Repo: var-flotsam/compbio-tutor, which Ethan creates (sessions can't create repos).

## Open
- R in every track vs. track 3 only (decision card posted; draft assumes every track).
- Ethan to widen the cloud environment's network access (JAX, Dryad, MGI, Ensembl hosts).
- QTL Viewer redistribution terms (not needed if Dryad + MPD suffice).
