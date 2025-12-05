#!/bin/bash
set -e

echo "Starting Build Validation..."

# Ensure pub-cache is in PATH for melos
export PATH="$PATH":"$HOME/.pub-cache/bin"

# 1. Check if Melos is installed/bootstrapped
if [ ! -f "melos.yaml" ]; then
    echo "Error: melos.yaml not found."
    exit 1
fi

# 2. Run Analysis
echo "Running Analysis..."
# Try running via script alias, if fails, fallback to direct exec (or just use direct exec for CI stability)
# Using direct exec to avoid 'melos not found' issues when running via 'dart run melos run' without global activation
dart run melos exec --concurrency 1 -- dart analyze .

# 3. Run Formatting Check
echo "Running Format Check..."
dart run melos exec --concurrency 1 -- dart format --set-exit-if-changed .

# 4. Simulate Build (Placeholder)
echo "Simulating Server Build..."
if [ -d "packages/dartzen_core" ]; then
    echo "Core package found."
else
    echo "Error: Core package missing."
    exit 1
fi

echo "Build Validation Passed!"
