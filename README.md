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

You write R in **Positron**, a free editor made for R, and Claude Code sits in a
panel beside your code as your tutor.

1. Install R: https://cran.r-project.org/ (Windows: "Download R for Windows" >
   base; Mac: the `.pkg` for your chip).
2. Install Positron: https://positron.posit.co/download.html
3. In Positron, choose **File > Open Folder...** and make and open a folder for
   the course, such as `Documents/compbio`.
4. Open the Extensions view (Ctrl+Shift+X, or Cmd+Shift+X on a Mac), search for
   **Claude Code** by Anthropic, install it, open its panel and sign in. If it
   isn't listed, set Positron's `gallery source` setting to Open VSX Registry
   and restart Positron.
5. In the Claude Code panel, type `/plugins`, add the marketplace
   `var-flotsam/compbio-tutor` and install **compbio-tutor**. (In a terminal
   instead: `/plugin install compbio-tutor --marketplace var-flotsam/compbio-tutor`.)
6. Type `/compbio-tutor:compbio-tutor` (or say "I'd like to start a compbio
   lesson"). The tutor checks your computer and walks you through the rest: R
   packages, your first R script, and the lessons.

You can also start from step 6 in any Claude Code terminal; the tutor will help
you install R and Positron.

### Where it runs

The tutor runs in Claude Code on the student's own computer. The intended setup
is the Claude Code panel in Positron; a terminal, the Code tab of the Claude
desktop app and VS Code also work. Lessons need R on that computer and a course
folder to keep work in. It does not work in regular claude.ai chat, and cloud
sessions (Claude Code on the web or in the mobile app) are not supported. To use
a phone, run Claude Code on a laptop and drive it from the phone with Remote
Control (https://code.claude.com/docs/en/remote-control).

The plugin's `compbio-tutor` command finds R wherever the installer put it, so
students never edit PATH or other settings. A plugin hook stops Claude from
changing the student's code, data or progress in the course folder, whatever
permission mode Claude Code is in.

## Repository layout

- `.claude-plugin/marketplace.json`: makes this repo a plugin marketplace
- `plugin/`: the plugin; the skill is `plugin/skills/compbio-tutor/`, and
  `plugin/bin/compbio-tutor` is the command that finds R and runs the tutor, and
  `plugin/hooks/` holds the guard that keeps Claude out of the student's files
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
