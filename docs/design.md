# compbio-tutor design

Status: **draft for Ethan's approval** (Phase 2). Nothing past this document is
built yet. Research behind these choices is in [research.md](research.md).

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
- Every correctness decision is made by a deterministic script with pytest tests.
- A capstone that follows the real DO islet study from phenotype to genome scan to
  candidate genes to the knockout experiments, with accurate claims throughout.

**Non-goals**
- Not a general bioinformatics assistant or a research pipeline.
- No live data fetching during lessons (offline, bundled data only).
- No grading of free-form essays or code style; we grade answers and outputs.
- No student accounts, servers or dashboards.

## 2. Who uses it, and where

**Students:** ages roughly 15-20, some Python helpful but not required for tracks
1-2 (the skill can teach the needed Python in passing). Track 3 assumes tracks 1-2
or equivalent.

**Teachers:** run a pilot with the teacher guide; no coding needed to install.

**Surfaces.** The docs show three runtimes with different limits (research.md §1).
The skill is built for the strictest one so it works on all three:

| Constraint | Design response |
|---|---|
| API runtime has no network and no installs | Graders use **only the Python standard library**; all lesson data ships in `assets/` |
| claude.ai and API reject non-spec frontmatter | `SKILL.md` uses only `name`, `description`, `license`, `compatibility`, `metadata` |
| Skills do not sync between surfaces | Release a zip for claude.ai upload; Claude Code users copy the folder to `.claude/skills/` |

Minimum Python: **3.11** (for `tomllib`). To verify against each runtime in Phase 3;
if a runtime is older, problem files switch from TOML to JSON.

## 3. Repository layout

```
compbio-tutor/                    repo root
├── skills/compbio-tutor/         the shippable skill (name matches folder)
├── prep/                         data build pipeline, not shipped (R/qtl2 + Python)
├── tests/                        pytest: graders, problem files, skill checks
├── evals/                        scripted student conversations, runner, results
├── docs/                         design.md, research.md, HANDOFF.md, teacher-guide.md
├── tools/package_skill.py        builds dist/compbio-tutor.zip for claude.ai upload
├── .github/workflows/ci.yml
├── pyproject.toml, uv.lock       uv-managed; dev deps only (pytest, ruff, mypy)
├── README.md
├── LICENSE (code), LICENSE-content (lesson text), DATA_SOURCES.md
```

Dev tooling: uv, ruff (lint + format), mypy in strict mode on `skills/` and `tools/`,
pytest. Runtime code in the skill has no third-party dependencies.

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
│   ├── tutor.py                  one CLI: list, show, dataset, grade, hint, explain, progress
│   └── tutorlib/                 graders, problem loader, progress store (stdlib only)
├── problems/<problem-id>/
│   ├── problem.toml              goal, background, starter data, grader spec, hints
│   └── explanation.md            worked explanation (read only via tutor.py explain)
└── assets/data/                  bundled datasets + ATTRIBUTION.md (budget: 10 MB)
```

One CLI keeps `SKILL.md` short: Claude learns one command shape
(`python scripts/tutor.py <verb> <problem-id> ...`) and every verb prints
student-safe output.

## 5. Problem format

Each problem is a folder with a `problem.toml`:

```toml
id = "t1-gc-content"
track = 1
title = "How much of this DNA is G or C?"
goal = "Compute GC content and explain why it differs between genomes."
background = """Plain-language background, 1-3 short paragraphs, original text."""
prompt = """What the student is asked to do."""
data = "generated"            # or a path under assets/data/
answer_format = "decimal fraction between 0 and 1, 4 decimal places"

[grader]
kind = "numeric"              # numeric | exact | sequence | set | choice | interval | ranking
tolerance = 0.001

[[grader.diagnostics]]        # recognised wrong answers -> feedback code
code = "percent_not_fraction"
message = "Your number looks like a percentage. The question asks for a fraction."

[[hints]]
text = "Which letters count toward GC content?"
[[hints]]
text = "Count each letter separately before combining."
[[hints]]
text = "Divide by the length of the whole sequence, including A and T."
```

Rules: at least 3 hints, ordered from a question to a near-procedure, and **no
hint states the answer**. Expected answers are never stored in text Claude reads:
graders compute them from the data (or from a seed), or keep them inside
`tutorlib`, whose source Claude runs but does not need to read.

**Per-student datasets.** Track 1 and some track 2 problems can generate a dataset
from a seed (`tutor.py dataset t1-gc-content --seed 42`), like Rosalind's
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

**Hints** are released one at a time with `tutor.py hint <id>`, which records the
level and refuses to skip ahead. Claude never reads the full hint list.

**Explanations** come only from `tutor.py explain <id>`, which prints the worked
explanation only if (a) the problem is graded correct in this session, or (b) all
hints are used and `--student-asked` is passed. Otherwise it prints a refusal and
the next hint. This puts the "no answer before trying" rule in code, not just in
instructions. (Claude could still read the file directly; the instructions forbid
it and evals measure it.)

**Progress** lives in `.compbio-tutor/progress.json` in the working directory:
attempts, hints used, solved problems. On claude.ai and the API it lasts for the
conversation only; that is acceptable for a pilot.

## 7. Teaching workflow (SKILL.md)

SKILL.md gives Claude a short loop, with a copyable checklist:

1. **Place the student.** Ask what they know; suggest a track and problem
   (`tutor.py list`). Check prerequisites for track 3.
2. **Set up the problem.** `tutor.py show <id>` prints goal, background, prompt and
   data location. Ask the student to predict or restate the goal first.
3. **Let them work.** Answer questions about Python syntax and biology concepts
   freely; do not do the problem's computation for them.
4. **Grade every answer with the script.** `tutor.py grade <id> --answer ...`.
   Never say "correct" or "incorrect" without a grader result.
5. **On a wrong answer:** use the feedback code, ask one guiding question, and
   offer the next hint only if they are stuck or ask.
6. **On a correct answer:** `tutor.py explain <id>`, then connect it to the
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

**Track 1: Sequences** (generated data plus one real mouse gene)
| id | Learning goal | Grader |
|---|---|---|
| t1-gc-content | GC content and why it varies | numeric |
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

**Track 3: Mouse genetics capstone** (Dryad + MPD derived extracts)
| id | Learning goal | Grader |
|---|---|---|
| t3-do-founders | The 8 founder strains (letters A-H) and why they matter | exact matching |
| t3-phenotype | Insulin secretion traits; distribution, log scale, sex difference | numeric |
| t3-genotype-probs | Reading founder probabilities for one mouse at one marker | exact + numeric |
| t3-single-marker-lod | Compute a LOD score at one marker by regression on founder dosages | numeric (vs. R/qtl2 value) |
| t3-genome-scan | Read a scan: peak chromosome, position, LOD vs. permutation threshold | interval + numeric |
| t3-support-interval | 1.5-LOD drop interval | interval |
| t3-heatmap | Chromosome heat map across secretion conditions; find a shared hotspot | interval + set |
| t3-founder-effects | Which founder alleles raise or lower the trait at a peak | set |
| t3-candidate-genes | Genes in the interval, filtered to protein-coding | set |
| t3-expression-ranking | Narrow candidates with islet expression (cis-eQTL, correlation with trait) | ranking |
| t3-knockout-test | What the *Hunk*, *Zfp148* and *Ptpn18* experiments showed and did not show | choice |
| t3-rqtl2-scan (optional) | Run the scan yourself in R/qtl2 (setup guide included) | numeric vs. precomputed |

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

Students use these CSVs with plain Python (stdlib `csv`, or pandas if they have
it). Graders compare to the R/qtl2 outputs with documented tolerances.

## 11. Testing, evals and CI

**pytest** (every grader, including wrong answers):
- For each problem: the correct answer passes; each listed diagnostic answer gets
  its code; random wrong answers fail; unparseable input gives `invalid`; seeded
  datasets reproduce.
- Problem file checks: ≥3 hints, no hint or background contains the expected
  answer, explanation exists, ids unique.
- Skill checks: frontmatter has only spec fields and valid name/description;
  SKILL.md under 500 lines; every referenced file exists; assets under budget;
  `tutorlib` imports only the standard library.

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

**CI (GitHub Actions):** on every push and PR: `uv sync`, `ruff check`,
`ruff format --check`, `mypy`, `pytest`, `skills-ref validate`, and a packaging
dry run. Evals run on manual dispatch only, because they need an API key secret
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
| Students on claude.ai can't run Python locally | Problems accept answers computed anywhere; Claude can also run the student's own code when they paste it |
| Runtime Python older than 3.11 | Switch problem files to JSON |

## 14. Decisions I need from Ethan

1. **Approve this design** (or tell me what to change).
2. **GitHub repo:** create `var-flotsam/compbio-tutor` (or name another) and attach
   it to the project; until then commits stay local.
3. **Licenses:** MIT for code, CC BY 4.0 for lesson text?
4. **Pilot surface:** will students mostly use claude.ai or Claude Code? It
   changes how much the lessons lean on running code.
5. **Data build:** for Phase 6, broader network access for the cloud session, or
   run `prep/` on your computer?
