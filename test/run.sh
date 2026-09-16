#!/bin/sh
# Run the vimf90 test suite.
#
#   sh test/run.sh                       everything
#   sh test/run.sh textobj project       only test_textobj.vim and test_project.vim
#   VF90_TEST=Test_name sh test/run.sh   a single test
#   VIM=nvim sh test/run.sh              run against Neovim
#
# Exits non-zero if any test failed, so CI can use it directly.

here=$(cd "$(dirname "$0")" && pwd)

VIM=${VIM:-vim}
command -v "$VIM" >/dev/null 2>&1 || { echo "$VIM not found"; exit 127; }

VF90_FILES="$*"
VF90_REPORT=${VF90_REPORT:-$(mktemp -t vimf90-report.XXXXXX)}
export VF90_FILES VF90_REPORT

# The runner cannot print to stdout: in silent-ex mode :echo goes nowhere. It
# appends to $VF90_REPORT as it goes, which is shown here whatever the outcome
# so that a hang or a crash still leaves a readable partial report.
#
# Vim's own stdout is parked in a log instead: :make pipes the compiler through
# 'shellpipe', whose default tees to the terminal, and the resulting diagnostics
# would bury the report. The default is left alone deliberately — with tee in
# place v:shell_error reports tee's status rather than the compiler's, which is
# exactly the condition the build-status tests exist to pin down.
log="$VF90_REPORT.log"
"$VIM" -es -u "$here/vimrc" -S "$here/run.vim" </dev/null >"$log" 2>&1
status=$?

[ -s "$VF90_REPORT" ] && cat "$VF90_REPORT"
if [ "$status" -ne 0 ] && [ -s "$log" ]; then
  echo
  echo "--- vim output (last 20 lines) ---"
  tail -20 "$log"
fi
rm -f "$VF90_REPORT" "$log"
exit $status
