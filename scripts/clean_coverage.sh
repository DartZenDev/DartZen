#!/usr/bin/env bash
# Remove old coverage artifacts to ensure fresh collection
set -euo pipefail

echo "Cleaning old coverage artifacts..."
find . -type d -name coverage -prune -exec rm -rf {} + || true
find . -type f -name "*.lcov" -delete || true
find . -type f -name "*.vm.json" -delete || true
rm -f scripts/coverage_uncovered.csv || true
echo "Clean complete."

exit 0
