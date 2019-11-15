#!/bin/bash

if [[ "$TRAVIS" != "true" ]]; then
  echo "This script is intended to be run on Travis CI" 1>&2
  exit 1
fi

set -ev

# Check tag name conflicts
vim --cmd "try | helptags doc/ | catch | cquit | endtry" --cmd quit

# # Validate changelog
# ruby scripts/check-changelog.rb
