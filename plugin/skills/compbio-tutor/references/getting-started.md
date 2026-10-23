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
- Step 2: Positron and a course folder
- Step 3: Claude Code inside Positron
- Step 4: R packages
- Step 5: First R script and the working directory
- If something goes wrong

## How to run this part
- Run `compbio-tutor doctor`. If it says R isn't installed, start at step 1.
  Otherwise fix **only the first** failing item, then run `doctor` again. One
  step per turn. Students never need to change PATH or other settings: the
  `compbio-tutor` command finds R wherever the installer put it.
- Ask whether the student is already in Positron with the Claude Code panel open
  on their course folder. If so, skip steps 2-3.
- For each step: say what it is and why it's needed (one or two sentences), give
  the exact click path or command, ask the student to do it and tell you what
  happened.
- You may run read-only checks inside the course folder (`doctor`, `pwd`, `ls`)
  yourself. Installing R and Positron and making the course folder are for the
  student to do. Ask before running anything that installs software, and never
  use `sudo` or administrator commands on the student's behalf: show the command
  and let them run it.
- If the student is on a school-managed computer and an install is blocked,
  stop and suggest they ask their teacher. Don't look for workarounds. If
  Positron can't be installed, the course still works from a terminal: the
  student edits files in any editor and you run them with `compbio-tutor run`.
- Celebrate each green check. Setup is the hardest part for many students.

## Words to teach along the way
Introduce each when it first matters, in one sentence:
- **Editor**: where you write and save code. In Positron it's the big pane in
  the middle.
- **Console**: where R runs your code and prints results, below the editor.
- **Folder (directory)** and **path**: where a file lives, such as
  `data/t1-gc-content.fasta` inside the course folder.
- **Working directory**: the folder R is "standing in". Relative paths such as
  `data/x.fasta` are looked up from there.
- **Package**: an add-on to R written by other people. Biostrings knows about DNA.

## Step 1: Install R
Why: R is the programming language for every lesson. The tutor's answer
checker is written in R too.

First find out which computer they have (ask, or run `uname -s`: `Darwin` is a
Mac, `MINGW...` or `MSYS...` is Windows, `Linux` is Linux).
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

## Step 2: Positron and a course folder
Why: Positron is a free editor made for R. It suggests function names as you
type, shows help when you hover over a function, runs one line at a time, and
shows your variables and plots. Keeping every course file in one folder means R
and the tutor can always find the data.

1. Download Positron from https://positron.posit.co/download.html and install
   it like any other app.
2. Open Positron, choose **File > Open Folder...**, go to Documents, make a new
   folder called `compbio` (the dialog has a New Folder button), and open it.
   If OneDrive manages Documents, any folder they can find again is fine.
3. The R console starts at the bottom. If Positron asks which R to use, pick the
   one from step 1.

## Step 3: Claude Code inside Positron
Why: with Claude in a panel next to the code, the student can select lines and
ask about them, and the tutor sees the same folder.

1. Open the Extensions view (the four-squares icon on the left, or
   Ctrl+Shift+X / Cmd+Shift+X), search for **Claude Code**, check that the
   publisher is **Anthropic**, and click **Install**.
2. If it doesn't appear, open Settings (Ctrl+, / Cmd+,), search for
   `gallery source`, choose **Open VSX Registry**, restart Positron, and search
   again.
3. Open the Claude Code panel (the Claude icon in the sidebar, or the Command
   Palette: **Claude Code: Open**) and sign in.
4. The tutor plugin is shared with any Claude Code they used before. If it's
   missing, type `/plugins`, add the marketplace `var-flotsam/compbio-tutor` and
   install **compbio-tutor**.
5. Type `/compbio-tutor:compbio-tutor` in the panel to start the tutor there.

A new Claude session doesn't remember this conversation, but `doctor` picks up
where setup left off. Before the student switches, tell them exactly what to
type when they come back.

## Step 4: R packages
Run `compbio-tutor doctor --install-packages` (ask first; it downloads and can take a
few minutes). It installs Biostrings from Bioconductor, the standard source of
biology packages for R, into `.compbio-tutor/library` inside the course folder,
so nothing outside the folder changes. `doctor` also writes a two-line
`.Rprofile` in the folder: R runs that file whenever it starts here, and it
tells R to use the course's packages. Then ask the student to restart R in
Positron (the circular-arrow restart button on the console) so the console
picks up those packages. Explain the new files in a sentence if the student
asks. If the install fails, show the student the last lines of the output and
suggest they share them with their teacher.

## Step 5: First R script and the working directory
Before lesson 1, have the student run one script themselves:
1. **File > New File > R File**, then type:
   ```r
   print("Hello from R")
   getwd()
   ```
   Save it as `hello.R` in a `work` folder inside the course folder (the Save
   dialog can make the folder). You don't write it for them.
2. Put the cursor on the first line and press Ctrl+Enter (Cmd+Enter on a Mac).
   The line runs in the console and the cursor moves down. Press it again for
   `getwd()`.
3. Put the cursor on `print` and press F1: help for that function opens. This
   is where to look first when they wonder what a function does.
4. Ask: what folder did `getwd()` print, and why? (Positron starts R in the
   folder they opened, the course folder.) Then explain that the lessons read
   files like `data/t1-gc-content.fasta`, which only works when the working
   directory is the course folder. That's why they always open the course folder,
   not a single file.
5. Respond to their answer before moving on: confirm what they got right, fix
   any misunderstanding, and only then start placing them in a lesson.

## If something goes wrong
- "R isn't installed": step 1.
- "cannot open file 'data/...': No such file": wrong working directory (step 5;
  they opened a file instead of the folder, or ran `setwd()`), or the lesson
  hasn't been shown yet (`compbio-tutor show <id>` writes the data).
- "there is no package called 'Biostrings'" in the console: restart R (step 4)
  so the course `.Rprofile` runs.
- Permission errors when installing: a school-managed computer may block
  installs; ask the teacher.
- Anything else: copy the exact error message, read it together line by line,
  and run `doctor` again.
