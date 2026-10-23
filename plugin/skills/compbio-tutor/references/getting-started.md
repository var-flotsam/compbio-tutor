# Getting started: from zero to the first lesson

Use this when `tutor.py doctor` reports a problem or the student is new. Assume
an intro computer science student: they may never have used a terminal,
installed a programming language, or thought about folders and paths. Teaching
these is part of the lesson, so explain, then let the student do it.

## Contents
- How to run this part
- Words to teach along the way
- Step 1: Python for the grader
- Step 2: A course folder
- Step 3: Install R
- Step 4: Let the terminal find R (PATH)
- Step 5: R packages
- Step 6: First R script and the working directory
- Step 7: Editing files
- If something goes wrong

## How to run this part
- Run `tutor.py doctor` and fix **only the first** failing item, then run
  `doctor` again. One step per turn.
- For each step: say what it is and why it's needed (one or two sentences), give
  the exact command or click path, ask the student to do it and tell you what
  happened.
- The student types terminal commands themselves where it's safe, because this
  is a skill they're learning. You may run read-only checks (`doctor`, `pwd`,
  `ls`, `Rscript --version`) yourself. Ask before running anything that installs
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
- **PATH**: the list of folders the terminal searches for programs.
- **Package**: an add-on to R written by other people. Biostrings knows about DNA.

## Step 1: Python for the grader
The tutor's grading script is written in Python, so a working Python 3.9+ is
needed (students don't write Python).
- Try `python3`, then `python`, then `py -3` with `--version`, and use the
  first that works for every `tutor.py` command this session.
- **macOS**: running `python3` the first time may offer to install the
  "Command Line Developer Tools". Accept and wait for it to finish.
- **Windows**: if `python` opens the Microsoft Store or says it isn't found,
  have the student run `winget install --id Python.Python.3.12 -e`, then close
  and reopen the terminal and Claude Code.
- **Linux**: Python 3 is almost always installed; otherwise
  `sudo apt install python3` (the student runs it).

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

Whenever setup needs a restart (steps 2-4), give the student these steps and the
`/compbio-tutor:compbio-tutor` command to type when they return; a new Claude
Code session doesn't remember this conversation, but `doctor` picks up where
setup left off.

On Windows (Git Bash), `~/Documents` is the student's Documents folder too.
If OneDrive manages Documents, any folder they can find again is fine.

## Step 3: Install R
Why: R is the programming language for every lesson, and `Rscript` is the
program that runs an R file.
- Follow the install line that `doctor` prints for their operating system. On a
  Mac, `doctor` names the right download for their chip.
- After installing, the terminal must be restarted to notice R: `/exit`, close
  the terminal window, open a new one, `cd ~/Documents/compbio`, `claude`, then
  `/compbio-tutor:compbio-tutor`.
- Check: `Rscript --version` prints a version 4.3 or newer.

## Step 4: Let the terminal find R (PATH)
Mostly on Windows: the R installer doesn't add R to PATH. `doctor` prints a
one-line command that adds it for the student's install. Explain what PATH is,
have them run it, then restart the terminal and Claude Code as in step 3.

## Step 5: R packages
Run `tutor.py doctor --install-packages` (ask first; it downloads and can take a
few minutes). It installs Biostrings from Bioconductor, the standard source of
biology packages for R. If it fails, show the student the last lines of the
output and suggest they share them with their teacher.

## Step 6: First R script and the working directory
Before lesson 1, have the student run one script so they see how it works:
1. Make a folder for their code: `mkdir -p work`.
2. Create `work/hello.R` containing:
   ```r
   print("Hello from R")
   getwd()
   ```
   (Offer to create the file for them this one time, or let them use an editor.)
3. Run it from the course folder: `Rscript work/hello.R`.
4. Ask: what folder did `getwd()` print, and why? (It's the folder they ran the
   command from: their working directory.) Then explain that the lessons read
   files like `data/t1-gc-content.fasta`, which only works when the working
   directory is the course folder. That's why every lesson runs
   `Rscript work/<problem>.R` from `~/Documents/compbio`.
5. Respond to their answer before moving on: confirm what they got right, fix
   any misunderstanding, and only then start placing them in a lesson.

If the student uses RStudio or the R console instead of `Rscript`, they set the
working directory with `setwd("~/Documents/compbio")`, or in RStudio with
File > New Project > Existing Directory > the course folder. Check with
`getwd()`.

## Step 7: Editing files
Students edit their starter code in `work/`. Use the editor their class uses. If
they have none, suggest Visual Studio Code (free, https://code.visualstudio.com/)
and opening the course folder in it (File > Open Folder). Remind them to save
before running a script.

## If something goes wrong
- "command not found": the program isn't installed or isn't on PATH (steps 3-4).
- "cannot open file 'data/...': No such file": wrong working directory (step 6)
  or the lesson hasn't been shown yet (`tutor.py show <id>` writes the data).
- Permission errors when installing: a school-managed computer may block
  installs; ask the teacher.
- Anything else: copy the exact error message, read it together line by line,
  and run `doctor` again.
