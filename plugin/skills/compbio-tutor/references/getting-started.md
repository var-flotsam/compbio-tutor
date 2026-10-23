# Getting started: from zero to the first lesson

Use this when `compbio-tutor doctor` reports a problem, says R isn't installed,
or the student is new. Assume
an intro computer science student: they may never have used a terminal,
installed a programming language, or thought about folders and paths. Teaching
these is part of the lesson, so explain, then let the student do it.

## Contents
- How to run this part
- Words to teach along the way
- Step 1: Install R
- Step 2: A course folder
- Step 3: R packages
- Step 4: First R script and the working directory
- Step 5: Editing files
- If something goes wrong

## How to run this part
- Run `compbio-tutor doctor`. If it says R isn't installed, start at step 1.
  Otherwise fix **only the first** failing item, then run `doctor` again. One
  step per turn. Students never need to change PATH or other settings: the
  `compbio-tutor` command finds R wherever the installer put it.
- For each step: say what it is and why it's needed (one or two sentences), give
  the exact command or click path, ask the student to do it and tell you what
  happened.
- The student types terminal commands themselves where it's safe, because this
  is a skill they're learning. You may run read-only checks inside the course
  folder (`doctor`, `pwd`, `ls`) yourself. Installing R and making the course
  folder (steps 1-2) are for the student to do. Ask before running anything that installs
  software, and never use `sudo` or administrator commands on the student's
  behalf: show the command and let them run it.
- If the student is on a school-managed computer and an install is blocked,
  stop and suggest they ask their teacher. Don't look for workarounds.
- Celebrate each green check. Setup is the hardest part for many students.

## Words to teach along the way
Introduce each when it first matters, in one sentence:
- **Terminal**: a window where you type commands instead of clicking. Claude
  Code runs inside one.
- **Command**: a program name plus options, such as `mkdir compbio`.
- **Folder (directory)** and **path**: where a file lives, such as
  `~/Documents/compbio/data/t1-gc-content.fasta`. `~` means your home folder.
- **Working directory**: the folder a program is "standing in". Relative paths
  such as `data/x.fasta` are looked up from there.
- **Package**: an add-on to R written by other people. Biostrings knows about DNA.

## Step 1: Install R
Why: R is the programming language for every lesson. The tutor's answer
checker is written in R too.

First find out which computer they have (ask, or run `uname -s`: `Darwin` is a
Mac, `MINGW...` or `MSYS...` is Windows with Git Bash, `Linux` is Linux).
- **Windows**: download the installer from
  https://cran.r-project.org/bin/windows/base/ and accept the defaults.
- **macOS**: download the `.pkg` from https://cran.r-project.org/bin/macosx/
  for their chip (`uname -m` prints `arm64` for Apple silicon, `x86_64` for
  Intel), open it and click through the installer.
- **Linux**: `sudo apt install r-base libcurl4-openssl-dev` on Ubuntu or Debian
  (the second package lets R build Biostrings' helpers) (the student runs
  it); other systems: https://cran.r-project.org/.

No restart or PATH change is needed afterwards: run `compbio-tutor doctor`
again, and it finds the new R by itself.

## Step 2: A course folder
Why: keeping every file for the course in one folder means R and the tutor can
always find the data, and nothing gets mixed up with other files.

Claude Code works in the folder it was started from, so the student needs to
leave, make the folder, and start again inside it. Before they go, tell them
exactly what to type when they come back. Steps:
1. Type `/exit` to leave Claude Code (the terminal stays open).
2. `pwd` shows where you are now.
3. `mkdir -p ~/Documents/compbio` makes the folder (`-p` makes parent folders too
   and is fine if it already exists).
4. `cd ~/Documents/compbio` moves into it. Run `pwd` again to see the change.
5. `claude` starts Claude Code here. Then type `/compbio-tutor:compbio-tutor`
   and press Enter to bring the tutor back.

Whenever setup
needs a restart, give the student these steps and the
`/compbio-tutor:compbio-tutor` command to type when they return; a new Claude
Code session doesn't remember this conversation, but `doctor` picks up where
setup left off.

On Windows (Git Bash), `~/Documents` is the student's Documents folder too.
If OneDrive manages Documents, any folder they can find again is fine.

## Step 3: R packages
Run `compbio-tutor doctor --install-packages` (ask first; it downloads and can take a
few minutes). It installs Biostrings from Bioconductor, the standard source of
biology packages for R, into `.compbio-tutor/library` inside the course folder,
so nothing outside the folder changes. `doctor` also writes a two-line
`.Rprofile` in the folder: R runs that file whenever it starts here, and it
tells R to use the course's packages. Explain this in a sentence if the student
asks what the new files are. If it fails, show the student the last lines of the
output and suggest they share them with their teacher.

## Step 4: First R script and the working directory
Before lesson 1, have the student run one script so they see how it works:
1. Make a folder for their code: `mkdir -p work`.
2. Create `work/hello.R` containing:
   ```r
   print("Hello from R")
   getwd()
   ```
   (The student makes the file in their editor, step 5; you don't write it, so
   they never get a permission prompt.)
3. Run it for them with `compbio-tutor run work/hello.R` and show the output.
4. Ask: what folder did `getwd()` print, and why? (It's the folder they ran the
   command from: their working directory.) Then explain that the lessons read
   files like `data/t1-gc-content.fasta`, which only works when the working
   directory is the course folder. That's why every lesson
   runs from `~/Documents/compbio`.
5. Respond to their answer before moving on: confirm what they got right, fix
   any misunderstanding, and only then start placing them in a lesson.

If the student uses RStudio, they should open the course folder as a project
(File > New Project > Existing Directory > the course folder), so the working
directory and the course's packages are both set. Check with `getwd()`.

## Step 5: Editing files
Students edit their starter code in `work/`. Use the editor their class uses. If
they have none, suggest Visual Studio Code (free, https://code.visualstudio.com/)
and opening the course folder in it (File > Open Folder). Remind them to save
before running a script.

## If something goes wrong
- "R isn't installed": step 1.
- "cannot open file 'data/...': No such file": wrong working directory (step 4)
  or the lesson hasn't been shown yet (`compbio-tutor show <id>` writes the data).
- Permission errors when installing: a school-managed computer may block
  installs; ask the teacher.
- Anything else: copy the exact error message, read it together line by line,
  and run `doctor` again.
