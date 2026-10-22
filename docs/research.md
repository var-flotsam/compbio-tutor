# Phase 1 report: skill format, prior art, and data availability

Checked 2026-10-22. Every claim below links to the page it came from. Items marked
**unverified** could not be confirmed from this session and are listed again under
"Open questions" at the end.

## Contents
1. Agent Skills format (what the docs require)
2. Prior art and how this project differs
3. Data sources for the capstone and their terms
4. What the published papers say (for the worked example)
5. Practical constraints found during research
6. Open questions for Ethan

---

## 1. Agent Skills format

Sources: [Agent Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview),
[Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices),
[Claude Code skills](https://code.claude.com/docs/en/skills),
[Agent Skills specification](https://agentskills.io/specification).

**Layout.** A skill is a directory with a required `SKILL.md` and optional
`scripts/` (executable code), `references/` (docs read on demand) and `assets/`
(templates, data files). References should be one level deep from `SKILL.md`, and
reference files over 100 lines should start with a table of contents.

**Frontmatter.** `name` (max 64 chars; lowercase letters, digits, hyphens; no
leading, trailing or doubled hyphens; must match the directory name; may not
contain "anthropic" or "claude") and `description` (max 1,024 chars, third person,
says what the skill does *and* when to use it). Optional spec fields: `license`,
`compatibility` (max 500 chars), `metadata` (string map), `allowed-tools`
(experimental). Claude Code accepts more fields (`disable-model-invocation`,
`context`, `model`, ...), but claude.ai uploads and the Skills API **reject** any
field outside those six with a hard error. `compbio-tutor` is a valid name.

**Size.** `SKILL.md` body under 500 lines (about 5k tokens). Metadata costs about
100 tokens; everything else loads only when read.

**Scripts.** Claude runs bundled scripts with bash and sees only their output, not
their source. The docs recommend scripts for deterministic checks, explicit error
handling, documented constants, and a validate, fix, repeat loop. `SKILL.md` must
say whether to *run* a script or *read* it.

**Runtime differs by surface** (this shapes the design):

| Surface | Network | Installing packages |
|---|---|---|
| Claude Code | Full (same as the user's machine) | Allowed, local installs preferred |
| claude.ai | Full, partial or none (user/admin setting) | npm and PyPI allowed |
| Claude API (code execution) | None | None; pre-installed packages only |

Skills do not sync between surfaces; each is installed separately.

**Evaluation guidance.** Build at least three evaluations before writing much
content, test with Haiku, Sonnet and Opus, and compare runs with and without the
skill. The `skill-creator` plugin automates with/without comparisons using an
`evals/evals.json` format; `claude plugin eval` does the same for plugins.

**Validation tool.** `skills-ref validate ./compbio-tutor` checks frontmatter and
naming ([agentskills/skills-ref](https://github.com/agentskills/agentskills/tree/main/skills-ref)).

**Security note from the docs.** Skills that fetch external URLs are a risk,
because fetched content can carry instructions. That argues for bundling the
teaching data rather than fetching it live during a lesson.

## 2. Prior art

| Resource | What it is | Audience | Feedback model | Overlap with us |
|---|---|---|---|---|
| [Rosalind](https://rosalind.info/about/) | Problem set for bioinformatics through programming (UCSD and partners) | Self-learners who can program, plus course instructors | Automatic checking of a submitted answer; problem pages give background, input/output spec, sample data and error tolerance ([example](https://rosalind.info/problems/gc/)) | Track 1 topics (GC content, reverse complement, translation, ORFs) |
| [R/qtl2 site and guides](https://kbroman.org/qtl2/) (GPL-3) | Reference software for QTL mapping in DO and other crosses, with user guide and DO data-prep guides | Researchers, grad students | None (documentation) | Track 3 methods |
| [QTL mapping lesson](https://smcclatchy.github.io/mapping/) (McClatchy and Gatti) | Workshop lesson: genotype probabilities, scans, permutations, kinship, effects, SNP association, and a DO episode | Researchers new to R/qtl2 | Exercises with shown solutions | Track 3 concepts, in R |
| [qtl2data](https://github.com/rqtl/qtl2data) | Example datasets for R/qtl2, including several DO sets (DO_Recla, DO_Gatti2014, DOex) | R/qtl2 users | None | Possible small DO dataset for practice (no license stated; see §3) |
| [Teaching the Genome Generation](https://www.jax.org/education-and-learning/high-school-students-and-undergraduates/teaching-the-genome-generation) (JAX) | Teacher professional development: wet lab, bioinformatics and ethics, using human DNA | High school teachers and students | Teacher-led | Audience; good partner for a pilot |
| [Introduction to Applied Bioinformatics](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6343836/) (Caporaso) | Free, open, interactive text | Undergraduates | Runnable examples | Track 1 and 2 style |
| [Biology Meets Programming](https://www.coursera.org/learn/bioinformatics/home/info) (Coursera, UCSD) | MOOC with autograded coding | Beginners | Autograded quizzes | Track 1 |
| [Claude learning mode](https://engadget.com/ai/claudes-new-learning-mode-will-prompt-students-to-answer-questions-on-their-own-172057828.html) | General Socratic tutoring mode | Any student | Model judgment | Teaching style only |
| [LLM grading in a bioinformatics course](https://arxiv.org/html/2501.14499v1) | Study of LLM-graded assignments | Course staff | LLM as grader | The approach we deliberately avoid for correctness |

**How compbio-tutor differs.**
1. **A tutor, not a problem set or a manual.** Rosalind and Coursera check an
   answer; the R/qtl2 materials explain a method. This skill holds a conversation:
   it asks the student to predict, gives graded hints, and explains the biology
   after they succeed.
2. **Correctness comes from scripts, not the model.** Unlike general learning modes
   or LLM grading, every answer is checked by a deterministic grader with pytest
   tests, and the model only chooses which hint to give.
3. **One story from sequences to a published discovery.** No resource we found
   takes a high school student from GC content to reading a DO genome scan and
   following real candidate genes (Ptpn18, Hunk, Zfp148) to the knockout
   experiments that tested them.
4. **Scientific honesty is part of the spec.** The skill is told to separate "QTL
   region", "candidate gene" and "gene shown by experiment to affect secretion",
   and evals check for overclaiming.
5. **Lives where students already talk to Claude**, with no server to host.

All problem text in this repo will be original. We will not copy Rosalind problem
statements or lesson text; we cite them as further reading only.

## 3. Data sources and terms of use

| Source | What is there | Terms | Use in this project |
|---|---|---|---|
| **Dryad: "Data from: Genetic drivers of pancreatic islet function"** ([doi:10.5061/dryad.pj105](https://datadryad.org/dataset/doi:10.5061/dryad.pj105)) | `Attie_DO378_eQTL_viewer_v1.Rdata` (1.83 GB) plus README: genotypes, phenotypes and islet expression for 378 DO mice (Keller et al. 2018) | **CC0 1.0** (from the Dryad API license field) | **Primary source** for genotype probabilities, islet expression, clinical traits. Derived extracts can be redistributed; we cite anyway. |
| **Mouse Phenome Database, project Attie2** ([MPD:1020](https://phenome.jax.org/projects/Attie2)) | 76 measures from DO mice on a high-fat, high-sucrose diet, including ex vivo insulin secretion under 7 conditions (3.3, 8.3, 16.7 mM glucose; KCl; GLP-1; amino acids; palmitate) ([protocol](https://phenome-prod.jax.org/projects/Attie2/protocol)); per-animal downloads | [MPD terms](https://phenome.jax.org/about/termsofuse): contributors "waive copyright and related rights"; users "may freely build upon, enhance and reuse those data for any purpose"; scholarly citation expected; data "AS IS"; crawlers space requests ≥2 s | **Source for the insulin secretion phenotypes** used in the JCI 2019 paper. Cite MPD and the paper. |
| **QTL Viewer, Attie islet secretion** ([churchilllab.jax.org/qtlviewer/attie/islets](https://churchilllab.jax.org/qtlviewer/attie/islets)) | Interactive LOD, effect and mediation plots; "Download Data" gives an R data object. The JCI paper says all its data are available here. | **No terms of use or license shown** on the page or [user guide](https://qtlviewer.jax.org/userguide/userguide.pdf). Viewer code is MIT ([qtl2web](https://github.com/churchill-lab/qtl2web)). | Link students to it for exploration. **Do not redistribute its files** until terms are confirmed. |
| **Diversity Outbred Database** (dodb.jax.org) | Per JAX's [tools page](https://www.jax.org/research-and-faculty/genetic-diversity-initiative/tools-data): DO studies as CSV or R/qtl2 files, with an API | **Unverified**: the site blocks automated fetching (robots.txt), so I could not read its terms | Not needed if Dryad + MPD suffice |
| **MGI** ([reports](https://www.informatics.jax.org/downloads/reports/index.shtml)) | Gene coordinates (GRCm39: `MGI_Gene_Model_Coord.rpt`, `MRK_List2.rpt`), mouse-human orthology (`HOM_MouseHumanSequence.rpt`) | [**CC BY 4.0**](https://www.informatics.jax.org/mgihome/other/copyright.shtml) for data and annotations; images may not be redistributed | Track 2 lookups; gene lists for QTL intervals in track 3. Attribute MGI. |
| **Ensembl** | Gene, transcript, ortholog and variant data; REST API | [Disclaimer](https://mart.ensembl.org/info/about/legal/disclaimer.html): "no restrictions on access to, or use of, the data"; code Apache 2.0; some third-party data may carry constraints | Track 2 lookups; cite Ensembl |
| **qtl2data** ([GitHub](https://github.com/rqtl/qtl2data)) | Small DO datasets (DO_Recla, DOex) in R/qtl2 format | **No license file seen** in the repo listing | Avoid redistributing; optional external practice only |
| **SRA SRP125176** | Raw islet RNA-seq reads (per Keller 2018) | NCBI public data | Out of scope (too large for students) |

**Recommendation.** Build the capstone from Dryad (CC0) for genotypes and
expression, MPD Attie2 for insulin secretion traits, and MGI/Ensembl for gene
annotation. That covers everything the lessons need without depending on the QTL
Viewer's unstated terms. Two checks remain before Phase 6 (see Open questions):
that MPD animal IDs join to the Dryad mouse IDs, and what exactly the Dryad
README lists.

**Papers.** Both papers are free to read but not openly licensed (JCI: "©
2019 American Society for Clinical Investigation"; Genetics: "© 2018 Genetics
Society of America"; Europe PMC marks both as not open access). So the repo will
**paraphrase and cite** them, never copy text or figures. Any plot students see
will be regenerated from the data.

## 4. What the papers say (for the worked example)

**Keller et al. 2018, Genetics** ([PDF](https://kbroman.org/pdfs/keller2018.pdf),
doi:10.1534/genetics.118.300864): about 500 DO mice from generations 18, 19 and 21
on a high-fat, high-sucrose diet; GigaMUGA genotyping (143,259 markers); islet
RNA-seq on 378 mice after QC, quantified against the 8 founder transcriptomes;
eQTL hotspots with proposed drivers such as Hnf4a (Chr 2), Pdx1 (Chr 5), Fam83e
(Chr 7), Sat2 (Chr 11) and Il6st (Chr 13). Data: Dryad pj105; reads: SRA
SRP125176.

**Keller et al. 2019, JCI** ([article](https://www.jci.org/articles/view/129143),
doi:10.1172/JCI129143): islets from 483 DO mice, insulin secretion measured in 479
under seven conditions. Insulin secretion QTL include hotspots near Chr 1 (~30-34
Mb), Chr 3 (~135 Mb) and Chr 9 (~66 Mb), and condition-specific loci on Chr 16 for
GLP-1 (~91 Mb, near Hunk) and KCl (~32 Mb, near Zfp148). Three candidates were
tested in engineered mice:

- **Ptpn18** (Chr 1): a catalytically inactive knock-in. Male mutants on the
  high-fat, high-sucrose diet had better glucose tolerance and lower insulin, and
  their islets secreted less insulin to amino acids and palmitate.
- **Hunk** (Chr 16): whole-body knockout islets secreted more insulin in nearly
  every condition, so Hunk acts as a negative regulator of secretion in islets.
  In vivo insulin during an oral glucose tolerance test did not differ.
- **Zfp148** (Chr 16): beta-cell knockout islets from diet-fed mice secreted about
  3-fold more insulin at high glucose, so Zfp148 also acts as a negative
  regulator. Total in vivo insulin AUC did not differ significantly.

These positions are approximate, taken from the article page, and will be checked
against the data and MGI coordinates (GRCm39 vs. the paper's build) in Phase 6.
The nuance matters for teaching: the knockouts show an effect in *those* mouse
models, which is not the same as proving the natural DO variant acts through that
gene, and neither paper shows an effect on human diabetes.

## 5. Practical constraints found during research

- **This cloud session cannot download from JAX, Dryad or MGI hosts directly**
  (the network policy refuses the connection); only page reads work. Building the
  capstone extracts needs either broader network access for the session or a run
  on Ethan's machine.
- **The Dryad file is 1.83 GB**, far too big to bundle. The skill will ship small
  derived CSVs (a few MB at most), and a separate, reproducible `prep/` pipeline
  will rebuild them from the source files.
- **The Claude API runtime has no network and no installs**, so the shipped
  graders should use only the Python standard library (or packages verified to be
  pre-installed), and lessons must work offline from bundled data.

## 6. Open questions for Ethan

1. **GitHub repo:** should I push to a new repo (for example
   `var-flotsam/compbio-tutor`) that you create and attach, or to an existing one?
2. **Licenses:** I suggest MIT for code and CC BY 4.0 for lesson text. OK?
3. **QTL Viewer terms:** do you want to ask the Churchill lab whether its download
   files may be redistributed? Not needed if Dryad + MPD work out.
4. **Data build access:** for Phase 6, should I get broader network access in a
   cloud environment, or run the data-prep step on your computer?
5. **Unverified:** DODB terms; whether MPD Attie2 IDs match Dryad DO378 IDs; the
   object list in the Dryad README. I will confirm these at the start of Phase 6.
