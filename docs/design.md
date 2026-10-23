# compbio-tutor design

Status: **approved by Ethan 2026-10-22**, with these answers: Claude Code is the
pilot surface, students should learn R, MIT for code and CC BY 4.0 for lesson text.
Revised the same day for those answers. Students use R in all three tracks
(Ethan's choice, 2026-10-22). Research behind these choices is in [research.md](research.md).

## Contents
1. Goals and non-goals
2. Who uses it, and where
3. Repository layout
4. Skill layout
5. Problem format
6. Graders, hints and explanations
7. Teaching workflow (what SKILL.md tells Claude to do)
8. Boundaries
9. Tracks and problem list
10. Data pipeline for the capstone
11. Testing, evals and CI
12. Documentation
13. Risks
14. Decisions I need from Ethan

---

## 1. Goals and non-goals

**Goals**
- An open-source Agent Skill that tutors high school and intro college students
  through computational biology on real public data, by asking, hinting and
  checking rather than answering.
- Every correctness decision is made by a deterministic script with testthat tests.
- A capstone that follows the real DO islet study from phenotype to genome scan to
  candidate genes to the knockout experiments, with accurate claims throughout.

**Non-goals**
- Not a general bioinformatics assistant or a research pipeline.
- No live fetching of web pages during lessons. The one download is a versioned
  capstone data pack from this repo's GitHub Releases, verified by SHA-256.
- No grading of free-form essays or code style; we grade answers and outputs.
- No student accounts, servers or dashboards.

## 2. Who uses it, and where

**Students:** ages roughly 15-20. They write **R** (no prior coding assumed;
Track 0 "R basics" teaches the R the course uses, and each problem lists the R
basics it needs so the tutor can offer them just in time). Track 3 assumes tracks 1-2 or
equivalent.

**Teachers:** run a pilot with the teacher guide. Students need Claude Code; the
tutor handles everything after that (see "Onboarding from zero" below).

**Onboarding from zero** (added 2026-10-23 at Ethan's request; audience: an intro
CS course). Students install the tutor inside Claude Code with one command
(`/plugin install compbio-tutor --marketplace var-flotsam/compbio-tutor`); the
repo is a plugin marketplace. Every session starts with `tutor.R doctor`, which
checks R, the course folder and R packages and prints one next
step (if `Rscript` itself is missing, the setup guide covers installing R and PATH). `references/getting-started.md` teaches the terminal, folders, installing
R on each OS, PATH, packages, the working directory and an editor, one step per
turn, with the student typing the commands. After any restart the student types
`/compbio-tutor:compbio-tutor` to bring the tutor back.

**Files stay in the course folder** (Ethan, 2026-10-23: "The skill should not
read, write, or modify files outside the working directory"). The tutor command
resolves every path it uses against the course folder and refuses anything
outside it (including `..` and symlinks out); R packages install into
`.compbio-tutor/library` with a two-line course `.Rprofile`; SKILL.md tells Claude
to stay in the folder and to show, not run, setup steps that touch the rest of the
computer. The point is that students never see a permission prompt: the tutor
reads its own guides through `tutor.R guide <name>`, which allowed-tools
pre-approves, so it never opens files in the plugin folder directly. R's own
temporary session folder is the one thing outside, and R deletes it itself.

**No settings for students** (Ethan, 2026-10-23: the skill should be seamless).
The plugin's `bin/compbio-tutor` command finds R wherever the installer put it and
runs both the tutor and the student's scripts (`compbio-tutor run work/x.R`), so no
one edits PATH. Students ask the tutor to run their code.

**Surface: Claude Code.** Students work in a project folder that contains the skill
in `.claude/skills/compbio-tutor/`, with full network access and R installed
locally. Claude can run the student's R code and the graders.

| Need | Design response |
|---|---|
| Students learn R | Starter code, examples and hints are in R. Track 1 uses base R plus Bioconductor `Biostrings`, track 2 uses data frames, and track 3 uses R/qtl2. |
| Reproducible R setup | `tutor.R doctor` reports what is missing in plain language and `--install-packages` installs it |
| One language for students | Graders and the tutor command are base R (changed from Python on 2026-10-23 at Ethan's request), so students install only R. Graders check answers, not code. |
| Capstone data too big to bundle | `tutor.R fetch-data` downloads a versioned data pack from GitHub Releases once and verifies its SHA-256 |
| Portability later | `SKILL.md` frontmatter still uses only the six spec fields, so a claude.ai version stays possible (tracks 1-2 only) |

Minimum version on students' computers: R 4.3 or later (nothing else). Development
also uses Python 3.11+ with uv for the repository checks and the eval runner.

## 3. Repository layout

```
compbio-tutor/                    repo root
├── .claude-plugin/marketplace.json  makes the repo a plugin marketplace
├── plugin/                       the plugin; skill in plugin/skills/compbio-tutor/
├── prep/                         data build pipeline, not shipped (R/qtl2)
├── solutions/                    reference R solutions, outside the plugin
├── tests/testthat/               testthat: graders, problems, CLI, doctor, R solutions
├── tests/test_skill.py           pytest: skill folder follows the Agent Skills spec
├── evals/                        scripted student conversations, runner, results
├── docs/                         design.md, research.md, HANDOFF.md, teacher-guide.md
├── tools/package_skill.py        builds dist/compbio-tutor.zip for claude.ai upload
├── .github/workflows/ci.yml
├── pyproject.toml, uv.lock       uv-managed dev tools for repo checks and evals (pytest, ruff, mypy)
├── .lintr                        lintr settings for the R code
├── README.md
├── LICENSE (code), LICENSE-content (lesson text), DATA_SOURCES.md
```

Dev tooling: testthat and lintr for the R code; uv, ruff, mypy (strict) and pytest for
the Python repo checks and evals. Runtime code in the skill is base R only.

## 4. Skill layout

```
skills/compbio-tutor/
├── SKILL.md                      teaching workflow, < 300 lines
├── references/
│   ├── teaching-rules.md         hint policy, tone, when to reveal
│   ├── boundaries.md             what to decline and how to redirect
│   ├── track1-sequences.md       problem index: ids, goals, background (no answers)
│   ├── track2-genes.md
│   ├── track3-capstone.md
│   └── science-claims.md         what the papers did and did not show
├── scripts/
│   ├── tutor.R                   one CLI: doctor, list, show, dataset, grade, hint, explain, progress
│   └── R/                        graders, datasets/answers, problem loader, progress, doctor (base R)
├── problems/<problem-id>/
│   ├── problem.R                 goal, background, dataset, grader spec, hints
│   ├── starter.R                 starter code with ___ blanks
│   └── explanation.md            worked explanation (read only via tutor.R explain)
└── assets/data/                  bundled datasets + ATTRIBUTION.md (budget: 10 MB)
```

One CLI keeps `SKILL.md` short: Claude learns one command shape
(`Rscript scripts/tutor.R <verb> <problem-id> ...`) and every verb prints
student-safe output.

## 5. Problem format

Each problem is a folder with a `problem.R` that defines one list (read with
`sys.source()`, so authors write plain R and the skill needs no parser):

```r
problem <- list(
  id = "t1-gc-content", track = 1L, order = 1L,
  title = "How much of this DNA is G or C?",
  goal = "Read a FASTA file in R, count bases, and compute GC content.",
  dataset = "t1.gc_dna",          # seeded generator in scripts/R/answers.R
  answer = "t1.gc_content",       # computes the expected answer and diagnostics
  starter = "starter.R",
  answer_format = "a fraction between 0 and 1, rounded to 4 decimal places",
  background = r"(Plain-language background, 1-3 short paragraphs, original text.)",
  prompt = r"(What the student is asked to do.)",
  grader = list(kind = "numeric", tolerance = 0.0001),
  # numeric | exact | sequence | set | choice | interval | ranking
  hints = c(
    "Which letters count toward GC content?",
    "Count each letter separately before combining.",
    "Divide by the length of the whole sequence, including A and T."
  )
)
```

Recognised wrong answers (for example a percentage instead of a fraction) are
diagnostics returned by the answer function, each with a feedback code and message.

Rules: at least 3 hints, ordered from a question to a near-procedure, and **no
hint states the answer**. Expected answers are never stored in text Claude reads:
graders compute them from the data (or from a seed), or keep them inside
`scripts/R/`, whose source Claude runs but does not read.

**Per-student datasets.** Track 1 and some track 2 problems can generate a dataset
from a seed (`tutor.R dataset t1-gc-content --seed 42`), like Rosalind's
per-attempt data, so classmates cannot share answers. Track 3 uses the fixed
real dataset.

## 6. Graders, hints and explanations

**Grader output** (JSON on stdout, one schema for all problems):

```json
{"problem": "t1-gc-content", "status": "incorrect",
 "code": "percent_not_fraction",
 "message": "Your number looks like a percentage. The question asks for a fraction.",
 "attempts": 2, "hints_used": 1, "hints_left": 2}
```

`status` is one of `correct`, `partial`, `incorrect`, `invalid` (unparseable).
`code` names a known misconception when one matches (for example
`reverse_not_complement`, `wrong_reading_frame`, `lod_from_wrong_chromosome`,
`interval_too_narrow`). The message never contains the expected answer.

**Grader kinds** cover all three tracks: numeric with tolerance, exact string,
DNA/protein sequence (case and whitespace insensitive, with diagnostics such as
reversed-only or complemented-only), set (order-free, with partial credit),
multiple choice, genomic interval (overlap and width checks), and ranking (top-k
match).

**Hints** are released one at a time with `tutor.R hint <id>`, which records the
level and refuses to skip ahead. Claude never reads the full hint list.

**Explanations** come only from `tutor.R explain <id>`, which prints the worked
explanation only if (a) the problem is graded correct in this session, or (b) all
hints are used and `--student-asked` is passed. Otherwise it prints a refusal and
the next hint. This puts the "no answer before trying" rule in code, not just in
instructions. (Claude could still read the file directly; the instructions forbid
it and evals measure it.)

**Progress** lives in `.compbio-tutor/progress.dcf` (plain-text R DCF) in the working directory:
attempts, hints used, solved problems. On claude.ai and the API it lasts for the
conversation only; that is acceptable for a pilot.

## 7. Teaching workflow (SKILL.md)

SKILL.md gives Claude a short loop, with a copyable checklist:

1. **Place the student.** Ask what they know; suggest a track and problem
   (`tutor.R list`). Check prerequisites for track 3.
2. **Set up the problem.** `tutor.R show <id>` prints goal, background, prompt and
   data location. Ask the student to predict or restate the goal first.
3. **Let them work.** Answer questions about R syntax and biology concepts
   freely; do not do the problem's computation for them.
4. **Grade every answer with the script.** `tutor.R grade <id> --answer ...`.
   Never say "correct" or "incorrect" without a grader result.
5. **On a wrong answer:** use the feedback code, ask one guiding question, and
   offer the next hint only if they are stuck or ask.
6. **On a correct answer:** `tutor.R explain <id>`, then connect it to the
   biology and the capstone story, then suggest the next problem.
7. **Asked for the answer early:** say why trying helps, offer the next hint.
   Only after hints run out and the student asks again, run
   `explain <id> --student-asked`.

Tone rules (in `references/teaching-rules.md`): short turns, one question at a
time, praise specific reasoning, admit uncertainty, and use real-world biology
without hype.

**Science claims** (in `references/science-claims.md`, read before track 3
explanations): QTL mapping finds regions associated with a trait; a candidate gene
is a hypothesis; knockouts test a gene's effect in a specific model; none of this
by itself shows an effect on human diabetes. Includes what each 2019 knockout did
and did not show (research.md §4).

## 8. Boundaries

In scope: human, mouse and other model organisms; general molecular biology and
genetics; the provided public data.

Declined, with a one-line reason and a return to the lesson
(`references/boundaries.md`): pathogens of concern and toxins; designing or
modifying organisms, proteins or sequences for function (for example "change this
sequence so the protein works better" or codon optimisation for expression);
personal medical advice or interpreting a student's own genetic test. Track 1
stays analytic: count, reverse, translate and find ORFs in given sequences, never
design. Evals include boundary probes.

## 9. Tracks and problem list

Problem text is all original. Ids are stable; titles may change.

**Track 0: R basics** (added 2026-10-23; small generated data, graded like the others)
| id | Learning goal | Grader |
|---|---|---|
| r0-variables | Run a script, variables, arithmetic, `round()` | numeric |
| r0-vectors | Vectors, comparisons, `sum()` of logicals | numeric |
| r0-strings | `readLines()`, `nchar()`, `substr()`, `toupper()` | exact |
| r0-counting | `strsplit()`, `table()`, `max()` | numeric |
| r0-files | FASTA lines, `startsWith()`, `paste(collapse = "")` | numeric |
| r0-functions | `function()`, `if`/`else`, `for`, `grepl()` | numeric |

Data frames and plotting join Track 0 when tracks 2-3 are built.

**Track 1: Sequences** (generated data plus one real mouse gene)
| id | Learning goal | Grader |
|---|---|---|
| t1-gc-content | GC content and why it varies (first R: strings, vectors, `table()`) | numeric |
| t1-revcomp | Strands, 5'→3', reverse complement | sequence (diagnoses reverse-only, complement-only) |
| t1-transcribe-translate | DNA → RNA → protein with the standard code | sequence |
| t1-reading-frames | Six reading frames | set |
| t1-longest-orf | Start/stop codons and ORFs | sequence + interval |
| t1-mouse-insulin | Translate the mouse *Ins2* coding sequence (from Ensembl) and find the signal peptide region given its length | sequence; leads into track 3 |

**Track 2: Genes and genomes** (bundled MGI/Ensembl snapshots; live lookup
optional in Claude Code)
| id | Learning goal | Grader |
|---|---|---|
| t2-read-gene-record | Chromosome, start, end, strand, genome build | exact fields |
| t2-genes-in-interval | Which genes overlap a region | set |
| t2-orthologs | Mouse-human orthologs (e.g. *Hunk*/*HUNK*) and what orthology means | set |
| t2-what-is-a-snp | Compare founder sequences at a site; alleles and genotypes | exact + choice |
| t2-genome-builds | Why coordinates differ between GRCm38 and GRCm39 | choice |

**Track 3: Mouse genetics capstone** (R/qtl2 on the Dryad + MPD data pack; students
run the real analysis rather than only reading precomputed results)
| id | Learning goal | Grader |
|---|---|---|
| t3-do-founders | The 8 founder strains (letters A-H) and why they matter | exact matching |
| t3-phenotype | Insulin secretion traits; distribution, log scale, sex difference | numeric |
| t3-genotype-probs | Reading founder probabilities for one mouse at one marker | exact + numeric |
| t3-single-marker-lod | Compute a LOD score at one marker by hand with `lm()`, then check it against `scan1()` | numeric (vs. R/qtl2 value) |
| t3-genome-scan | Run `scan1()` with kinship and covariates, run permutations, and read the scan: peak chromosome, position, LOD vs. threshold | interval + numeric |
| t3-support-interval | 1.5-LOD drop interval | interval |
| t3-heatmap | Chromosome heat map across secretion conditions; find a shared hotspot | interval + set |
| t3-founder-effects | Use `scan1blup()` and plot founder effects; which founder alleles raise or lower the trait | set |
| t3-candidate-genes | Genes in the interval, filtered to protein-coding | set |
| t3-expression-ranking | Narrow candidates with islet expression (cis-eQTL, correlation with trait) | ranking |
| t3-knockout-test | What the *Hunk*, *Zfp148* and *Ptpn18* experiments showed and did not show | choice |

Which traits and loci appear in track 3 is fixed in Phase 6 after the data is
checked; the table shows the shape, not final answers.

## 10. Data pipeline for the capstone

`prep/` (not shipped) rebuilds `assets/data/` reproducibly:

1. Download Dryad pj105 (`Attie_DO378_eQTL_viewer_v1.Rdata`), MPD Attie2 animal
   data, and MGI coordinate and orthology reports; record URL, date and checksum.
2. Join MPD animals to Dryad mice; stop with a clear error if IDs don't match.
3. In R/qtl2: compute genotype probabilities at a reduced marker set, kinship
   (LOCO), scans for the chosen secretion traits, permutation thresholds, and
   founder coefficients at peaks. R/qtl2 is used here because it is the honest
   way to do this analysis.
4. Export small CSVs: phenotypes for chosen traits, founder probabilities at a few
   markers, LOD scans (reduced grid), thresholds, coefficients, expression for
   genes in chosen intervals, MGI gene rows for those intervals.
5. Write `ATTRIBUTION.md` with citations and licenses; enforce the 10 MB budget.

The data pack (target under 200 MB) holds an R/qtl2 cross object with genotype
probabilities on a thinned marker grid, the chosen phenotypes and covariates, islet
expression for genes in the chosen intervals, MGI gene rows, and reference results
(scans, thresholds, BLUPs) that the graders compare against. Because permutations
and BLUPs involve randomness or fitting, graders use documented tolerances and
students set a fixed seed.

## 11. Testing, evals and CI

**testthat** (every grader, including wrong answers):
- For each problem: the correct answer passes; each listed diagnostic answer gets
  its code; random wrong answers fail; unparseable input gives `invalid`; seeded
  datasets reproduce.
- Problem file checks: ≥3 hints, no hint or background contains the expected
  answer, explanation exists, ids unique.
- Skill checks (pytest): frontmatter has only spec fields and valid name/description;
  SKILL.md under 500 lines; every referenced file exists; assets under budget;
  the tutor's R code uses base R only.

**Evals** (`evals/`): scripted student conversations run against Claude with the
skill installed. Personas per problem sample: correct first try, partly wrong
(hits a diagnostic), stuck (needs all hints), asks for the answer early, and a
boundary probe. Scores:
- **Grader accuracy:** did Claude call the grader before every verdict, and did
  its stated verdict match the grader's?
- **Hint leakage:** does the expected answer (or a near variant) appear in
  Claude's turns before it is allowed? Checked by string/number matching.
- **Explanation accuracy:** a per-problem checklist of required points and
  forbidden overclaims (e.g. "this gene causes diabetes"), scored by an LLM judge
  with the checklist, plus regex for the forbidden phrases.
- **Boundary handling:** declined and returned to the lesson.

The runner will use the Claude Agent SDK with the skill on the filesystem (to
confirm in Phase 7), test with Haiku, Sonnet and Opus as the docs advise, and
write a results table into the README.

**CI (GitHub Actions):** on every push and PR: `ruff`, `mypy`, `pytest` and
`skills-ref validate` for the skill folder, and lintr for the R code. An R job on
Linux, macOS and Windows (plus R 4.3 on Linux) runs a CLI smoke test with base R,
installs packages with `doctor --install-packages` as students do, and runs the
testthat suite, including each reference R solution graded by the tutor, so a broken R setup or a tolerance drift fails CI. Evals run on manual dispatch only, because they need an API key secret
and cost money.

## 12. Documentation

- **README:** audience, install for Claude Code and claude.ai, a sample capstone
  session, eval results, limits, data credits.
- **docs/teacher-guide.md:** one page: setup, a 3-5 session pilot plan, what to
  watch for, how to report problems.
- **docs/HANDOFF.md:** current state, kept up to date each phase.

## 13. Risks

| Risk | Mitigation |
|---|---|
| MPD and Dryad mouse IDs don't join | Check first in Phase 6; fall back to Dryad 2018 traits (still islet biology) and tell Ethan |
| Paper loci differ from what our reduced scans show | Teach from our scans; say where and why they differ |
| Claude reads explanation files directly | Instructions forbid it; evals measure leakage |
| Overclaiming disease links | science-claims.md, explanation checklists, forbidden-phrase evals |
| R setup fails on school computers | `tutor.R doctor`, the setup guide, a teacher-guide troubleshooting section, and a test on a clean machine in CI (`r-lib/actions`) |
| Scans too slow on student laptops | Thinned marker grid, fewer permutations in class (with the full threshold supplied), timing checked in CI |
| Grader tolerance too tight for different R/BLAS versions | Tolerances set from runs on Linux, macOS and Windows in CI |

## 14. Decisions

Settled 2026-10-22: design approved; Claude Code is the pilot surface; students
learn R; MIT for code, CC BY 4.0 for lesson text; repo `var-flotsam/compbio-tutor`
(Ethan to create); the cloud environment's network access to be widened for the data
build.

Also settled 2026-10-22: students use R in all three tracks.
