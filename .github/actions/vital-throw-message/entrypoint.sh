#!/bin/sh

if [ -n "${GITHUB_WORKSPACE}" ] ; then
  cd "${GITHUB_WORKSPACE}" || exit 1
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

INPUT_BASEDIR="autoload/vital/__latest__/"
INPUT_TARGETS="*.vim"

# shellcheck disable=SC2046
go run -mod=mod /scripts/lint-throw.go $(find "${INPUT_BASEDIR}" -type f -name "${INPUT_TARGETS}") \
  | reviewdog -efm="%f:%l:%c: %m" -name="vital-throw-message"  \
              -reporter="${INPUT_REPORTER:-'github-pr-check'}" \
              -level="${INPUT_LEVEL}"
