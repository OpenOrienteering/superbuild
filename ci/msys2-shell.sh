#!/bin/bash
source /etc/profile
set -x
unset CC
unset PKG_CONFIG_PATH
"$@"
