# compbio-tutor

A Claude skill that tutors high school and intro college students through
computational biology in R, using real public data. It asks questions, gives
hints, checks answers with deterministic graders, and explains the biology.

Work in progress. See `docs/design.md` for the plan and `docs/HANDOFF.md` for
current status. The full README (install, sample session, eval results, limits)
comes in Phase 7.

## Development

```
uv sync
uv run pytest
Rscript setup/check_setup.R --install   # for the R solution tests
```
