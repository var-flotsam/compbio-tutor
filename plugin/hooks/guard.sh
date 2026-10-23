#!/usr/bin/env bash
# PreToolUse guard: in a compbio-tutor course folder, Claude never changes the
# student's code (work/), their data (data/) or the tutor's records
# (.compbio-tutor/). This holds in every permission mode, including Auto.
# Outside a course folder it does nothing. Reads the hook JSON on stdin.

input=$(cat)

# Value of a top-level or nested JSON string field (first match), unescaped
# enough for paths and commands.
field() {
  printf '%s' "$input" | tr -d '\n' |
    sed -n -E "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"(([^\"\\\\]|\\\\.)*)\".*/\\1/p" |
    sed -e 's/\\\\/\//g' -e 's/\\"/"/g'
}

deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' \
    "compbio-tutor: in a course folder the tutor never changes files in work/, data/ or .compbio-tutor/. The student writes their own code: point to the line and give a hint instead."
  exit 0
}

cwd=$(field cwd)
[ -n "$cwd" ] || cwd=$PWD
[ -d "$cwd/.compbio-tutor" ] || exit 0

protected='(work|data|\.compbio-tutor)'
tool=$(field tool_name)

case "$tool" in
  Edit | Write | MultiEdit | NotebookEdit)
    path=$(field file_path)
    [ -n "$path" ] || path=$(field notebook_path)
    [ -n "$path" ] || exit 0
    case "$path" in
      /* | [A-Za-z]:/*) ;;
      *) path="$cwd/$path" ;;
    esac
    # Windows paths differ only in case.
    lower_path=$(printf '%s' "$path" | tr '[:upper:]' '[:lower:]')
    lower_cwd=$(printf '%s' "${cwd%/}" | tr '[:upper:]' '[:lower:]')
    case "$lower_path" in
      "$lower_cwd"/*) rel=${path:$((${#lower_cwd} + 1))} ;;
      *) exit 0 ;;
    esac
    # "..", "." and "//" make a path hard to judge, so they are refused here.
    if printf '%s' "/$rel" | grep -Eq '/\.\.?(/|$)|//'; then deny; fi
    if printf '%s' "$rel" | grep -Eq "^$protected(/|$)"; then deny; fi
    ;;
  Bash)
    cmd=$(field command)
    case "$cmd" in compbio-tutor\ * | compbio-tutor) exit 0 ;; esac
    # Shell commands that write into the protected folders.
    quiet=$(printf '%s' "$cmd" | sed -E 's/[0-9]?>(&[0-9]|[[:space:]]*\/dev\/null)//g')
    if printf '%s' "$quiet" | grep -Eq "$protected/" &&
      printf '%s' "$quiet" | grep -Eq '>|\b(sed[[:space:]]+-i|tee|cp|mv|rm|touch|truncate|perl[[:space:]]+-[a-z]*i|writeLines|cat[[:space:]]*<<)\b'; then
      deny
    fi
    ;;
esac
exit 0
