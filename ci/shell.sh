#!/bin/bash
if [ -n "${MINGW}" ] ; then
  source /etc/profile
  echo "CC:=$CC, unset"
  unset CC
  unset PKG_CONFIG_PATH
  echo "PATH:=$PATH"
  cygpath -w /usr/bin
fi

unset UNBUFFER
if [ -f /usr/bin/stdbuf ] ; then
  UNBUFFER="/usr/bin/stdbuf -oL"
elif [ -f /usr/bin/unbuffer ] ; then
  UNBUFFER="/usr/bin/unbuffer"
fi

set -o pipefail

${UNBUFFER} "$@" 2>&1 | ${UNBUFFER} sed -f "${BUILD_SOURCESDIRECTORY}/ci/filter-stderr.sed"
