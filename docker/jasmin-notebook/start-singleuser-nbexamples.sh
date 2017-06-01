#!/bin/bash

# Starts notebook server with extra params for nbexamples

set -e

exec sh /usr/local/bin/start-singleuser.sh  \
  --Examples.reviewed_example_dir="$NBEXAMPLES_REVIEWED_DIR"  \
  --Examples.unreviewed_example_dir="$NBEXAMPLES_UNREVIEWED_DIR"  \
  $@
