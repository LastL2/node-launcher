#!/bin/bash

check_gnu() {
  $1 --version | head -n 1 | grep -q "GNU" && return
  echo "GNU $1 is required." >/dev/tty
  FAILED=1
}

check_gnu grep
check_gnu awk
check_gnu find
check_gnu sed

if [ -n "$FAILED" ]; then
  if [ "$(uname)" == "Darwin" ]; then
    echo >/dev/tty
    echo "Mac OS can try the following to update native utilities to GNU version (homebrew):" >/dev/tty
    echo "brew install coreutils binutils diffutils findutils gnu-tar gnu-sed gawk grep" >/dev/tty
  fi
  echo >/dev/tty
  exit 1
fi
