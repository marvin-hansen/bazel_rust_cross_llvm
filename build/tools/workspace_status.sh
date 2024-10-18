#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

echo "STABLE_GIT_COMMIT $(git rev-parse --short HEAD)"
