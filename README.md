# compbio-tutor

A Claude Code plugin that tutors high school and intro college students through
computational biology in R, using real public data. It asks questions, gives
hints, checks answers with deterministic graders, and explains the biology. It
assumes no prior experience with the terminal or R: it walks students through
setup, and Track 0 ("R basics") teaches the R the course uses before it is needed.

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

### Where it runs

The tutor runs in Claude Code on the student's own computer: the terminal, the
Code tab of the Claude desktop app, or the VS Code extension. Lessons need R on
that computer and a course folder to keep work in. It does not work in regular
claude.ai chat, and cloud sessions (Claude Code on the web or in the mobile app)
are not supported yet. To use a phone, run Claude Code on a laptop and drive it
from the phone with Remote Control (https://code.claude.com/docs/en/remote-control).

The plugin's `compbio-tutor` command finds R wherever the installer put it, so
students never edit PATH or other settings.

## Repository layout

- `.claude-plugin/marketplace.json`: makes this repo a plugin marketplace
- `plugin/`: the plugin; the skill is `plugin/skills/compbio-tutor/`, and
  `plugin/bin/compbio-tutor` is the command that finds R and runs the tutor
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
