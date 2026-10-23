# compbio-tutor

A Claude Code plugin that tutors high school and intro college students through
computational biology in R, using real public data. It asks questions, gives
hints, checks answers with deterministic graders, and explains the biology. It
assumes no prior experience with the terminal or R and walks students through
setup.

Work in progress. See `docs/design.md` for the plan and `docs/HANDOFF.md` for
current status. The full README (sample session, eval results, limits) comes in
Phase 7.

## For students

1. Install Claude Code (your teacher will tell you how): https://code.claude.com/docs/en/setup
2. Open a terminal, start Claude Code with `claude`, and install the tutor:

   ```
   /plugin install compbio-tutor --marketplace var-flotsam/compbio-tutor
   ```

   On Claude Code older than 2.1.275, use two commands instead:

   ```
   /plugin marketplace add var-flotsam/compbio-tutor
   /plugin install compbio-tutor@compbio-tutor
   ```

3. Type `/compbio-tutor:compbio-tutor` (or say "I'd like to start a compbio lesson"). The tutor checks your computer and
   walks you through everything else: a folder for the course, installing R,
   R packages, and your first R script.

## Repository layout

- `.claude-plugin/marketplace.json`: makes this repo a plugin marketplace
- `plugin/`: the plugin; the skill is `plugin/skills/compbio-tutor/`
- `solutions/`: reference R solutions (kept out of the plugin)
- `tools/build_problems.py`: builds each `problem.json` from `problem.toml`
- `tests/`, `docs/`, `evals/`

## Development

```
uv sync
uv run python tools/build_problems.py   # after editing any problem.toml
uv run pytest
uv run ruff check . && uv run mypy
claude plugin validate .
```

The R solution tests need R 4.3+ and Biostrings
(`Rscript plugin/skills/compbio-tutor/scripts/check_setup.R --install`).
