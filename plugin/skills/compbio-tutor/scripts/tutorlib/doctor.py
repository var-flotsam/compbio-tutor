"""Check a student's computer for everything the lessons need.

Run by ``tutor.py doctor``. Prints a short checklist and one next step, in plain
language for a student new to the terminal. Never installs R itself; it can
install R packages once R works (``--install-packages``).
"""

from __future__ import annotations

import glob
import os
import platform
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path, PureWindowsPath

SCRIPTS_DIR = Path(__file__).resolve().parents[1]
CHECK_SETUP_R = SCRIPTS_DIR / "check_setup.R"
MIN_R = (4, 3)
MIN_PYTHON = (3, 9)
COURSE_FOLDER_NAME = "compbio"
# Installing Bioconductor packages from source can take several minutes on a
# slow school laptop; checking them takes a few seconds.
CHECK_TIMEOUT_S = 120
INSTALL_TIMEOUT_S = 1800


@dataclass
class Check:
    name: str
    ok: bool
    detail: str
    fix: str = ""


@dataclass
class Report:
    checks: list[Check] = field(default_factory=list)
    rscript: str | None = None

    @property
    def ok(self) -> bool:
        return all(check.ok for check in self.checks)

    def render(self) -> str:
        lines = ["compbio-tutor setup check", ""]
        for check in self.checks:
            lines.append(f"[{'ok' if check.ok else '!!'}] {check.name}: {check.detail}")
        first_fix = next((c for c in self.checks if not c.ok), None)
        lines.append("")
        if first_fix is None:
            lines.append("Everything is ready. Next step: start the first lesson.")
        else:
            lines.append(f"Next step ({first_fix.name}): {first_fix.fix}")
        return "\n".join(lines)


def os_name() -> str:
    """'macos', 'windows' or 'linux' (anything else is treated as linux)."""
    system = platform.system()
    if system == "Darwin":
        return "macos"
    if system == "Windows" or os.environ.get("MSYSTEM"):  # MSYSTEM: Git Bash on Windows
        return "windows"
    return "linux"


def candidate_rscripts(osname: str) -> list[str]:
    """Usual install locations, newest version first, for when Rscript isn't on PATH."""
    if osname == "windows":
        roots = [os.environ.get("PROGRAMFILES", r"C:\Program Files"), r"C:\Program Files"]
        found: list[str] = []
        for root in dict.fromkeys(roots):
            found += glob.glob(os.path.join(root, "R", "R-*", "bin", "Rscript.exe"))
        found += glob.glob("/c/Program Files/R/R-*/bin/Rscript.exe")
        return sorted(set(found), key=_version_key, reverse=True)
    if osname == "macos":
        return [
            "/Library/Frameworks/R.framework/Resources/bin/Rscript",
            "/opt/homebrew/bin/Rscript",
            "/usr/local/bin/Rscript",
        ]
    return ["/usr/bin/Rscript", "/usr/local/bin/Rscript"]


def _version_key(path: str) -> tuple[int, ...]:
    match = re.search(r"R-(\d+)\.(\d+)\.(\d+)", path)
    return tuple(int(part) for part in match.groups()) if match else (0,)


def find_rscript(osname: str) -> tuple[str | None, bool]:
    """Return (path, on_path). path is None when R isn't installed anywhere we know."""
    on_path = shutil.which("Rscript")
    if on_path:
        return on_path, True
    for path in candidate_rscripts(osname):
        if os.path.isfile(path):
            return path, False
    return None, False


def r_version(rscript: str) -> tuple[int, int, int] | None:
    try:
        result = subprocess.run(
            [rscript, "--version"], capture_output=True, text=True, timeout=CHECK_TIMEOUT_S
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    match = re.search(r"version (\d+)\.(\d+)\.(\d+)", result.stdout + result.stderr)
    if not match:
        return None
    major, minor, patch = (int(part) for part in match.groups())
    return major, minor, patch


def install_r_hint(osname: str) -> str:
    if osname == "windows":
        return (
            "Install R. Easiest: in the terminal run "
            "`winget install --id RProject.R -e`, or download the installer from "
            "https://cran.r-project.org/bin/windows/base/ and accept the defaults. "
            "Then close and reopen the terminal."
        )
    if osname == "macos":
        chip = "Apple silicon (arm64)" if platform.machine() == "arm64" else "Intel (x86_64)"
        return (
            "Install R. Download the .pkg for "
            f"{chip} Macs from https://cran.r-project.org/bin/macosx/, open it and "
            "click through the installer. Then close and reopen the terminal."
        )
    return (
        "Install R. On Ubuntu or Debian run `sudo apt install r-base`; on other "
        "Linux systems see https://cran.r-project.org/. Then reopen the terminal."
    )


def path_hint(osname: str, rscript: str) -> str:
    if osname == "windows":
        win = PureWindowsPath(rscript).parent
        # Git Bash spells C:\Program Files as /c/Program Files.
        drive = win.drive.rstrip(":").lower()
        folder = "/" + "/".join([drive, *win.parts[1:]]) if drive else win.as_posix()
        return (
            "R is installed but the terminal can't find it. Run this once, then "
            f"close and reopen the terminal: echo 'export PATH=\"$PATH:{folder}\"' >> ~/.bashrc"
        )
    folder = str(Path(rscript).parent)
    return (
        "R is installed but the terminal can't find it. Run this once, then reopen "
        f"the terminal: echo 'export PATH=\"$PATH:{folder}\"' >> ~/.zshrc ~/.bashrc"
    )


def folder_check(cwd: Path, home: Path) -> Check:
    suggestion = home / "Documents" / COURSE_FOLDER_NAME
    if cwd.resolve() in {home.resolve(), Path(cwd.anchor)}:
        return Check(
            "Course folder",
            False,
            f"you're working in {cwd}, which is a whole drive or your home folder",
            f"make a folder just for this course, such as {suggestion}, then start "
            "Claude Code from inside it (`mkdir -p` the folder, `cd` into it, run `claude`).",
        )
    if ".claude" in cwd.parts:
        return Check(
            "Course folder",
            False,
            f"you're inside Claude Code's own settings folder ({cwd})",
            f"start Claude Code from a course folder such as {suggestion} instead.",
        )
    return Check("Course folder", True, f"{cwd}")


def packages_check(rscript: str, install: bool) -> Check:
    args = [rscript, "--vanilla", str(CHECK_SETUP_R)] + (["--install"] if install else [])
    try:
        result = subprocess.run(
            args,
            capture_output=True,
            text=True,
            timeout=INSTALL_TIMEOUT_S if install else CHECK_TIMEOUT_S,
        )
    except subprocess.TimeoutExpired:
        return Check(
            "R packages",
            False,
            "the package check took too long",
            "try again on a faster connection, or ask your teacher.",
        )
    except OSError as err:
        return Check("R packages", False, f"couldn't run R ({err})", "ask your teacher.")
    missing = re.findall(r"\[!\] (\S+) is missing", result.stdout)
    if result.returncode == 0:
        return Check("R packages", True, "all installed")
    if missing:
        return Check(
            "R packages",
            False,
            f"missing {', '.join(missing)}",
            "install them: run `tutor.py doctor --install-packages` (it can take a few minutes).",
        )
    tail = "\n".join((result.stdout + result.stderr).strip().splitlines()[-5:])
    return Check("R packages", False, f"the check failed:\n{tail}", "ask your teacher.")


def run(*, install_packages: bool = False, cwd: Path | None = None) -> Report:
    osname = os_name()
    report = Report()
    cwd = cwd or Path.cwd()

    py_ok = sys.version_info[:2] >= MIN_PYTHON
    report.checks.append(
        Check(
            "Python",
            py_ok,
            f"{platform.python_version()} ({osname})",
            "install Python 3.9 or newer from https://www.python.org/downloads/",
        )
    )
    report.checks.append(folder_check(cwd, Path.home()))

    rscript, on_path = find_rscript(osname)
    report.rscript = rscript
    if rscript is None:
        report.checks.append(Check("R", False, "not installed", install_r_hint(osname)))
        return report
    version = r_version(rscript)
    if version is None:
        report.checks.append(
            Check("R", False, f"found at {rscript} but it didn't run", install_r_hint(osname))
        )
        return report
    shown = ".".join(str(part) for part in version)
    if version[:2] < MIN_R:
        needed = ".".join(str(part) for part in MIN_R)
        report.checks.append(
            Check("R", False, f"{shown} is too old (need {needed}+)", install_r_hint(osname))
        )
        return report
    report.checks.append(Check("R", True, f"{shown} at {rscript}"))
    if not on_path:
        report.checks.append(
            Check("R on PATH", False, "the terminal can't find Rscript", path_hint(osname, rscript))
        )
    report.checks.append(packages_check(rscript, install_packages))
    return report
