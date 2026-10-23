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
- `tests/`, `docs/`, `evals/`

## Development

The tutor, graders and tests are R; students need only R 4.3+.

```
Rscript plugin/skills/compbio-tutor/scripts/tutor.R doctor --install-packages
Rscript -e 'testthat::test_dir("tests/testthat")'   # needs testthat and withr
Rscript -e 'lintr::lint_dir(".")'
uv sync && uv run pytest && uv run ruff check . && uv run mypy   # skill-folder checks
claude plugin validate .
```

Problems live in `plugin/skills/compbio-tutor/problems/<id>/problem.R`; their
datasets and answer checkers are in `scripts/R/answers.R`.
