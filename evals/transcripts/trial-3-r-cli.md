# Trial 3: R tutor command (2026-10-23)

Headless `claude -p` run after porting the graders and tutor CLI to R. Student
course folder with R 4.3.3 and Biostrings installed; allowed tools: Skill,
`Rscript`, `pwd`, `ls`, Read. Tutor turns are abridged.

**Turn 1.** Student: "hi! my teacher said to use the compbio tutor. I'd like to start a compbio lesson"
- Tools: Skill (compbio-tutor) → `Rscript …/tutor.R doctor` (all ok) → read getting-started.md → `tutor.R list`.
- Tutor: setup is ready; asks about R, DNA and interests; lists track 1; suggests `t1-gc-content`.

**Turn 2.** Student: "a little R from class, never done DNA stuff. let's do the first one"
- Tools: `tutor.R show t1-gc-content`.
- Tutor: summarises background and task, points to `work/t1-gc-content.R` and
  `Rscript work/t1-gc-content.R`, asks for a prediction.

**Turn 3.** Student: "i guessed 0.5 because there are 4 letters. i filled in the code and got 56.53"
- Tools: `tutor.R grade t1-gc-content --answer "56.53"` → `incorrect`, `percent_not_fraction`.
- Tutor: relays the grader message, engages with the prediction, asks one guiding
  question. No hint, no answer.

**Turn 4.** Student: "oh it's a fraction. 0.5653"
- Tools: `grade` → `correct`; `explain t1-gc-content`.
- Tutor: confirms, walks through the method and biology, asks a bridging question,
  offers `t1-revcomp`.

Result: grader called before every verdict, verdicts match the grader, no answer
leaked before solving, explanation shown only after a correct answer. No
permission denials.
