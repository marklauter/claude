#!/usr/bin/env bash
# Validation loop for writing-csharp.
# format (solution-wide) -> build -> tests, fail fast.
#
# Output discipline:
#   - format / build: silent on success, captured output on failure.
#   - test: emits the test summary line and the coverage table row(s) on success,
#           full captured output on failure.
#
# Usage:
#   build-gate.sh                                  whole solution: format, build, test
#   build-gate.sh <test-target>                    solution-wide format; test scoped
#                                             (dotnet test builds the test target's
#                                             dependencies implicitly, so no explicit build)
#   build-gate.sh <build-target> <test-target>     solution-wide format; build scoped; test scoped
#                                             (use for non-paired test targets)
#
#   --filter <expr>   forward an xUnit trait filter to every dotnet test run, e.g.
#                     --filter "Category=Unit"   or   --filter "Category!=Integration"
#                     or   --filter "FullyQualifiedName~Parser". Composes with any target.
#
# Targets accept anything `dotnet` accepts: a project name, a .csproj path, or a .slnx/.sln path.

set -eo pipefail

FILTER=""
positional=()

while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h)
            awk 'NR==1 {next} /^#/ {sub(/^#/, ""); sub(/^ /, ""); print; next} {exit}' "${BASH_SOURCE[0]}"
            exit 0
            ;;
        --filter|-f)
            [ -n "${2:-}" ] || { echo "build-gate: --filter needs an expression" >&2; exit 2; }
            FILTER="$2"; shift 2
            ;;
        --filter=*) FILTER="${1#--filter=}"; shift ;;
        -f=*)       FILTER="${1#-f=}"; shift ;;
        --)         shift; while [ $# -gt 0 ]; do positional+=("$1"); shift; done ;;
        *)          positional+=("$1"); shift ;;
    esac
done
set -- "${positional[@]}"

ARG1="${1:-}"
ARG2="${2:-}"

# An xUnit trait filter, forwarded to each dotnet test call when set.
filter_args=()
[ -n "$FILTER" ] && filter_args=(--filter "$FILTER")

# Preflight: dotnet format runs solution-wide and auto-discovers a workspace at CWD.
# Bail with a clear message instead of letting dotnet emit a stack trace.
if ! compgen -G "*.sln*" > /dev/null && ! compgen -G "*.csproj" > /dev/null; then
    echo "build-gate: no .sln/.slnx/.slnf/.csproj found in $PWD" >&2
    echo "  cd into the directory that contains your solution or project file, then re-run." >&2
    exit 2
fi

run_step() {
    local label="$1"
    shift
    echo "==> $label"
    local output
    output=$("$@" 2>&1) || { local code=$?; echo "$output"; exit $code; }
}

test_step() {
    local label="$1"
    shift
    echo "==> $label"
    local output
    output=$("$@" 2>&1) || { local code=$?; echo "$output"; exit $code; }
    # Surface the test summary line(s) and the coverage table row(s) on success.
    echo "$output" | grep -E -i "(Failed|Passed|Skipped|Total):" | tail -10 || true
    echo "$output" | grep -E "^\|.*%" || true
}

run_step "format (solution-wide)" dotnet format --verify-no-changes --severity info --verbosity quiet

if [ -z "$ARG1" ]; then
    run_step "build (solution-wide)" dotnet build --nologo --verbosity quiet
    test_step "test (solution-wide)" dotnet test --nologo --verbosity quiet --logger "console;verbosity=minimal" "${filter_args[@]}"
elif [ -z "$ARG2" ]; then
    test_step "test $ARG1" dotnet test "$ARG1" --nologo --verbosity quiet --logger "console;verbosity=minimal" "${filter_args[@]}"
else
    run_step "build $ARG1" dotnet build "$ARG1" --nologo --verbosity quiet
    test_step "test $ARG2" dotnet test "$ARG2" --nologo --verbosity quiet --logger "console;verbosity=minimal" "${filter_args[@]}"
fi

echo "==> green"
