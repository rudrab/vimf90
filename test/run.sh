#!/bin/sh
# Run the vimf90 test suite.
#
#   sh test/run.sh                       everything
#   sh test/run.sh textobj project       only test_textobj.vim and test_project.vim
#   VF90_TEST=Test_name sh test/run.sh   a single test
#   VF90_VIM=nvim sh test/run.sh         run against Neovim
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
case "$(basename "$EDITOR_BIN")" in
  nvim*)
    "$EDITOR_BIN" --headless -u "$here/vimrc" -S "$here/run.vim" </dev/null >"$log" 2>&1
    ;;
  *)
    "$EDITOR_BIN" -es -u "$here/vimrc" -S "$here/run.vim" </dev/null >"$log" 2>&1
    ;;
esac
status=$?

[ -s "$VF90_REPORT" ] && cat "$VF90_REPORT"
if [ "$status" -ne 0 ] && [ -s "$log" ]; then
  echo
  echo "--- editor output (last 20 lines) ---"
  tail -20 "$log"
fi
rm -f "$VF90_REPORT" "$log"
exit $status
