#!/bin/sh
# Run the vimf90 test suite.
#
#   sh test/run.sh                       everything
#   sh test/run.sh textobj project       only test_textobj.vim and test_project.vim
#   VF90_TEST=Test_name sh test/run.sh   a single test
#   VF90_VIM=nvim sh test/run.sh         run against Neovim
#   VF90_TIMEOUT=600 sh test/run.sh      raise the 300s watchdog (0 disables)
#
# Exits non-zero if any test failed, so CI can use it directly.

here=$(cd "$(dirname "$0")" && pwd)

# Which editor to test. Note that this is deliberately NOT called VIM: $VIM is
# Vim's own variable for locating $VIMRUNTIME, and exporting VIM=nvim sets
# $VIMRUNTIME to "nvim", which breaks filetype detection and every runtime file
# with it -- silently, since the editor still starts and still runs the tests.
EDITOR_BIN=${VF90_VIM:-vim}

# A $VIM that is not a directory cannot be a runtime root, so it is only ever
# harmful here; most often it is someone following the old VIM=nvim spelling.
if [ -n "$VIM" ] && [ ! -d "$VIM" ]; then
  echo "note: ignoring \$VIM=$VIM (not a directory); use VF90_VIM to choose the editor" >&2
  unset VIM
fi

command -v "$EDITOR_BIN" >/dev/null 2>&1 || { echo "$EDITOR_BIN not found"; exit 127; }

VF90_FILES="$*"
VF90_REPORT=${VF90_REPORT:-$(mktemp -t vimf90-report.XXXXXX)}
export VF90_FILES VF90_REPORT

# The runner cannot print to stdout: with -es / --headless, :echo goes nowhere.
# It appends to $VF90_REPORT as it goes, which is shown here whatever the
# outcome so that a hang or a crash still leaves a readable partial report.
#
# The editor's own stdout is parked in a log instead: :make pipes the compiler
# through 'shellpipe', whose default tees to the terminal, and the resulting
# diagnostics would bury the report. That default is left alone deliberately --
# with tee in place v:shell_error reports tee's status rather than the
# compiler's, which is exactly the condition the build-status tests pin down.
log="$VF90_REPORT.log"

# A wedged editor must not outlive the run. This is not hypothetical: a broken
# $VIMRUNTIME once left nine headless Neovim instances running for over an hour,
# and they ignored SIGTERM, hence -s KILL rather than the default signal.
TIMEOUT=${VF90_TIMEOUT:-300}
limit=""
if [ "$TIMEOUT" -gt 0 ] 2>/dev/null && command -v timeout >/dev/null 2>&1; then
  limit="timeout -s KILL $TIMEOUT"
fi

# When the watchdog kills the editor, the shell announces it with a "Killed"
# line of its own. That comes from this script's shell rather than from the
# job, so silencing it means pointing this script's stderr away for the
# duration. Nothing is lost: the editor's own output is already going to $log.
exec 3>&2 2>/dev/null
case "$(basename "$EDITOR_BIN")" in
  nvim*)
    $limit "$EDITOR_BIN" --headless -u "$here/vimrc" -S "$here/run.vim" </dev/null >"$log" 2>&1
    ;;
  *)
    $limit "$EDITOR_BIN" -es -u "$here/vimrc" -S "$here/run.vim" </dev/null >"$log" 2>&1
    ;;
esac
status=$?
exec 2>&3 3>&-

[ -s "$VF90_REPORT" ] && cat "$VF90_REPORT"

# 137 is SIGKILL, which here means the run hit the limit above. Say so plainly:
# the partial report printed above is the last thing that happened before it
# stopped, which is the useful part.
if [ "$status" -eq 137 ]; then
  echo
  echo "TIMED OUT after ${TIMEOUT}s and was killed. Raise VF90_TIMEOUT if the"
  echo "suite is simply slow here; otherwise the report above ends at the hang."
fi

if [ "$status" -ne 0 ] && [ -s "$log" ]; then
  echo
  echo "--- editor output (last 20 lines) ---"
  tail -20 "$log"
fi
rm -f "$VF90_REPORT" "$log"
exit $status
