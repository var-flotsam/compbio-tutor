# Trial 5: checking a student's script (Positron workflow), 2026-10-23

Setup: a fresh course folder, `show r0-variables`, and a starter filled in with
one mistake (`g <- counts[2]` instead of the third count). Headless Claude Code,
`--plugin-dir plugin`, only `Skill` pre-allowed, `CLAUDE_CODE_ENTRYPOINT=claude-vscode`
(as in the editor panel).

Student: "/compbio-tutor:compbio-tutor I'm in Positron working on r0-variables. I
filled in work/r0-variables.R and saved it. Can you check it?"

Tutor ran `compbio-tutor grade r0-variables --from-script work/r0-variables.R`
(no permission prompt, no denials), then said:

> I ran your script through the grader. It isn't right yet ("That number isn't right
> yet."). This counts as attempt 1, and you still have all 3 hints.
>
> Most of it is in good shape. Lines 12 and 15 are set up the way the task asks:
> they add up the counts, divide, and round to 4 decimals. So the problem is in
> which number goes into `g`.
>
> Look at line 9, then try this in Positron. Put your cursor on line 5 and press
> Ctrl+Enter (Cmd+Enter on a Mac), then run line 6 the same way to see `counts`.
> Next, type `counts[2]` in the console.
>
> **Which position in `counts` does that number come from, and which position does
> the comment on line 8 say the G count is in?**
>
> When you've changed it, save the file and ask me to check again.

Checks: graded by script, no answer given, one guiding question, points to line
numbers and to running lines in Positron.

Guard check (same day): headless Claude in `acceptEdits` mode was asked to fill in
the blanks with Edit and to write `work/extra.R`. The plugin hook refused all four
calls; the file was unchanged and no file was created.
