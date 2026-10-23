# Trial session 2: setup from zero (2026-10-23)

Headless Claude Code with the plugin loaded via `--plugin-dir`. R was already
installed in the test container, so this trial covers the course-folder and
working-directory steps; the R-missing and PATH branches are covered by
`tests/test_doctor.py`.

## Turn 1 (Session A, started in the home folder)

**Student:** hi im in intro to CS and our teacher said to use this for the bio unit. i installed claude code and the compbio thing. ive never used R or the terminal really

[`python3 /home/claude/compbio-tutor/plugin/skills/compbio-tutor/scripts/tutor.py doctor`]

**Tutor:** Good news: Python, R and the R packages are all installed. The one thing left is the **course folder**.

Right now Claude Code is running in `/root`, which is your whole home folder. It's better to give this course its own folder so the data, your code and your progress stay in one place and don't get mixed up with other files.

**Terminal basics you'll use**
- **Terminal:** a window where you type commands instead of clicking. Claude Code runs inside one.
- **Folder** (also called a *directory*): where files live.
- **Working directory:** the folder a program is "standing in". R looks for files starting from there, which is why we want it to be the course folder.

**What to do** (you type these yourself, because it's a useful skill to learn):
1. Type `/exit` to leave Claude Code. The terminal window stays open.
2. Type `pwd` and press Enter. This prints where you are now.
3. Type `mkdir -p ~/Documents/compbio`. This makes the folder. The `~` means your home folder.
4. Type `cd ~/Documents/compbio`. This moves you into it. Run `pwd` again to see that it changed.
5. Type `claude` to start Claude Code in the new folder. Then say **"let's keep going with compbio setup"**.

Tell me what `pwd` prints after step 4, or ask me if anything looks different from what I described.

## Turn 2 (Session B, restarted in ~/Documents/compbio)

**Student:** ok pwd says /root/Documents/compbio. let's keep going with compbio setup

[`python3 /home/claude/compbio-tutor/plugin/skills/compbio-tutor/scripts/tutor.py doctor`]

**Tutor:** Setup is done. `doctor` shows all four checks green:

- Python 3.13
- the course folder, `/root/Documents/compbio`
- R 4.3.3
- the R packages, including Biostrings

One setup step is left: a first R script, so you can see how the working directory works.

1. Make a folder for your code: `mkdir -p work`
2. Create `work/hello.R` containing:
   ```r
   print("Hello from R")
   getwd()
   ```
   I can create the file for you this one time, or you can use your own editor.
3. From `/root/Documents/compbio`, run `Rscript work/hello.R`.

When you've run it, tell me what folder `getwd()` printed and why you think it printed that one.

## Turn 3 (Session B)

**Student:** i made it in vs code and ran it. it printed: [1] "Hello from R" [1] "/root/Documents/compbio" . i guess because thats where i am?

[`python3 /home/claude/compbio-tutor/plugin/skills/compbio-tutor/scripts/tutor.py list`]

**Tutor:** Setup is finished, and the course has five problems in Track 1 (sequences):

1. `t1-gc-content`: how much of this DNA is G or C?
2. `t1-revcomp`: the other strand
3. `t1-translate`: from gene to protein
4. `t1-reading-frames`: six ways to read a sequence
5. `t1-longest-orf`: find the hidden gene

Track 1 has no prerequisites, and each problem builds on the one before it.

Before you pick one, two quick questions:
- How much R have you used before, if any?
- How much DNA and genetics do you know? For example, do you know what a base pair or a codon is?

Unless you have a reason to start elsewhere, I'd begin with `t1-gc-content`.

## Findings

- Turn 1: `doctor` caught the home-folder problem and the tutor taught pwd/mkdir/cd and the restart. Good.
- First attempt at turn 2 (not shown): in the new session, "let's keep going with compbio setup" did not trigger the skill. Fixed by widening the skill description (set up / continue / resume) and telling students to type `/compbio-tutor:compbio-tutor` after any restart. The retry above triggered it.
- Turn 3: the tutor moved on without confirming the student's (correct) explanation of `getwd()`. Added an explicit step to getting-started.md.
