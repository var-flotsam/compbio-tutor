#!/usr/bin/env python3
"""compbio-tutor command line: the only interface Claude uses during a lesson.

    python scripts/tutor.py doctor [--install-packages]
    python scripts/tutor.py list
    python scripts/tutor.py show <problem-id>
    python scripts/tutor.py dataset <problem-id> [--seed N]
    python scripts/tutor.py grade <problem-id> (--answer TEXT | --answer-file PATH)
    python scripts/tutor.py hint <problem-id>
    python scripts/tutor.py explain <problem-id> [--student-asked]
    python scripts/tutor.py progress

Everything printed is safe to show the student: no command prints an expected
answer except ``explain`` once its conditions are met.
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from tutorlib import doctor  # noqa: E402
from tutorlib.problems import Problem, ProblemError, load_all  # noqa: E402
from tutorlib.progress import Progress, data_path, work_path  # noqa: E402


def _problem(problems: dict[str, Problem], pid: str) -> Problem:
    if pid not in problems:
        known = ", ".join(sorted(problems))
        sys.exit(f"Unknown problem {pid!r}. Known problems: {known}")
    return problems[pid]


def _ensure_dataset(problem: Problem, progress: Progress) -> Path:
    path = data_path(problem.id)
    if not path.is_file():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(problem.make_dataset(progress.get(problem.id).seed), encoding="utf-8")
    return path


def cmd_list(problems: dict[str, Problem], progress: Progress) -> None:
    track = 0
    for problem in problems.values():
        if problem.track != track:
            track = problem.track
            print(f"\nTrack {track}")
        state = progress.problems.get(problem.id)
        mark = "solved" if state and state.solved else ("started" if state else "")
        print(f"  {problem.id:<26} {problem.title}  {mark}".rstrip())


def cmd_show(problem: Problem, progress: Progress) -> None:
    path = _ensure_dataset(problem, progress)
    progress.save()
    print(f"# {problem.title}  ({problem.id})\n")
    print(f"Learning goal: {problem.goal}\n")
    print(problem.background + "\n")
    print("## Your task\n")
    print(problem.prompt + "\n")
    print(f"Answer format: {problem.answer_format}")
    print(f"Your data file: {path}")
    if problem.starter:
        work = work_path(problem.id)
        if not work.exists():
            work.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(problem.folder / problem.starter, work)
        print(f"Starter code (your copy to edit): {work}")
        print(f"Run it from this folder with: Rscript {work}")


def cmd_dataset(problem: Problem, progress: Progress, seed: int | None) -> None:
    state = progress.get(problem.id)
    if seed is not None and seed != state.seed:
        state.seed = seed
        state.attempts = state.hints_used = 0
        state.solved = state.revealed = False
    path = data_path(problem.id)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(problem.make_dataset(state.seed), encoding="utf-8")
    progress.save()
    print(f"Wrote {path} (seed {state.seed}).")


def cmd_grade(problem: Problem, progress: Progress, answer: str) -> None:
    state = progress.get(problem.id)
    # Grade against data regenerated from the seed, so editing the file can't change the key.
    verdict = problem.grade(answer, problem.make_dataset(state.seed))
    if verdict.status != "invalid":
        state.attempts += 1
    if verdict.status == "correct":
        state.solved = True
    state.last_code = verdict.code
    progress.save()
    print(
        json.dumps(
            {
                "problem": problem.id,
                "status": verdict.status,
                "code": verdict.code,
                "message": verdict.message,
                "attempts": state.attempts,
                "hints_used": state.hints_used,
                "hints_left": len(problem.hints) - state.hints_used,
                **verdict.details,
            },
            indent=2,
        )
    )


def cmd_hint(problem: Problem, progress: Progress) -> None:
    state = progress.get(problem.id)
    total = len(problem.hints)
    if state.hints_used >= total:
        print(
            f"All {total} hints are used. If the student still wants the answer, they can "
            f"ask for it: run `explain {problem.id} --student-asked`."
        )
        return
    text = problem.hints[state.hints_used]
    state.hints_used += 1
    progress.save()
    print(f"Hint {state.hints_used} of {total}: {text}")


def cmd_explain(problem: Problem, progress: Progress, student_asked: bool) -> None:
    state = progress.get(problem.id)
    hints_done = state.hints_used >= len(problem.hints)
    if state.solved or (student_asked and hints_done):
        if not state.solved:
            state.revealed = True
            progress.save()
        print(problem.explanation_path.read_text(encoding="utf-8"))
        return
    if student_asked:
        left = len(problem.hints) - state.hints_used
        print(
            f"Not yet: {left} hint(s) are left. Offer the next hint (`hint {problem.id}`) "
            "and encourage another try."
        )
    else:
        print(
            "Not yet: the problem isn't solved. The explanation unlocks after a correct "
            "answer, or after all hints are used and the student asks for the answer."
        )


def cmd_progress(problems: dict[str, Problem], progress: Progress) -> None:
    if not progress.problems:
        print("No problems started yet.")
        return
    for pid, state in progress.problems.items():
        title = problems[pid].title if pid in problems else "(unknown problem)"
        status = "solved" if state.solved else ("answer shown" if state.revealed else "open")
        print(f"{pid:<26} {status:<12} attempts={state.attempts} hints={state.hints_used}  {title}")


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(prog="tutor.py", description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="verb", required=True)
    sub.add_parser("list")
    doc = sub.add_parser("doctor")
    doc.add_argument("--install-packages", action="store_true")
    sub.add_parser("progress")
    for verb in ("show", "hint"):
        sub.add_parser(verb).add_argument("problem")
    ds = sub.add_parser("dataset")
    ds.add_argument("problem")
    ds.add_argument("--seed", type=int)
    gr = sub.add_parser("grade")
    gr.add_argument("problem")
    src = gr.add_mutually_exclusive_group(required=True)
    src.add_argument("--answer")
    src.add_argument("--answer-file", type=Path)
    ex = sub.add_parser("explain")
    ex.add_argument("problem")
    ex.add_argument("--student-asked", action="store_true")
    args = parser.parse_args(argv)

    if args.verb == "doctor":
        print(doctor.run(install_packages=args.install_packages).render())
        return

    try:
        problems = load_all()
    except ProblemError as err:
        sys.exit(f"Problem files are broken (tell the teacher): {err}")
    progress = Progress.load()

    if args.verb == "list":
        cmd_list(problems, progress)
    elif args.verb == "progress":
        cmd_progress(problems, progress)
    else:
        problem = _problem(problems, args.problem)
        if args.verb == "show":
            cmd_show(problem, progress)
        elif args.verb == "dataset":
            cmd_dataset(problem, progress, args.seed)
        elif args.verb == "grade":
            if args.answer_file is not None:
                try:
                    answer = args.answer_file.read_text(encoding="utf-8")
                except OSError as err:
                    sys.exit(f"Couldn't read the answer file: {err}")
            else:
                answer = args.answer
            cmd_grade(problem, progress, answer)
        elif args.verb == "hint":
            cmd_hint(problem, progress)
        elif args.verb == "explain":
            cmd_explain(problem, progress, args.student_asked)


if __name__ == "__main__":
    main()
