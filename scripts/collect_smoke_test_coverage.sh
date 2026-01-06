#!/usr/bin/env bash
# Quick smoke test collector for a single package. Detects whether the package
# uses Flutter and runs the appropriate test commands for dev/prd × linux/web
# without aborting on a single-platform failure.
set -euo pipefail


ROOT_DIR="$(pwd)"

echo "Cleaning coverage artifacts..."
bash "$ROOT_DIR/scripts/clean_coverage.sh"

# detect whether the package uses Flutter (simple heuristic)
is_flutter_package() {
	local pubspec="$PKG_DIR/pubspec.yaml"
	if [ -f "$pubspec" ]; then
		if grep -E "sdk:\s*flutter|^flutter:" -q "$pubspec"; then
			return 0
		fi
		if grep -q "^dependencies:\s*$" -A3 "$pubspec" | grep -q "flutter:"; then
			return 0
		fi
	fi
	return 1
}

ENVS=(dev prd)
PLATFORMS=(linux web)

# Build package list: if args provided, use them; otherwise iterate packages/ and apps/
if [ "$#" -gt 0 ]; then
	PKG_LIST=("$@")
else
	PKG_LIST=()
	for d in packages/* apps/*; do
		[ -d "$d" ] || continue
		[ -f "$d/pubspec.yaml" ] || continue
		PKG_LIST+=("$d")
	done
fi

for PKG_DIR in "${PKG_LIST[@]}"; do
	echo "Processing package/app: $PKG_DIR"
	if is_flutter_package; then
		echo "Detected Flutter package: $PKG_DIR"
	else
		echo "Detected Dart-only package: $PKG_DIR"
	fi

	for e in "${ENVS[@]}"; do
		for p in "${PLATFORMS[@]}"; do
			echo "Running tests for $PKG_DIR DZ_ENV=$e DZ_PLATFORM=$p"
			if is_flutter_package; then
				if [ "$p" = "web" ]; then
					(cd "$PKG_DIR" && flutter test --platform=chrome --dart-define=DZ_PLATFORM=$p --dart-define=DZ_ENV=$e --coverage) || true
					(cd "$PKG_DIR" && if [ -d coverage ]; then mv coverage coverage_tmp || true; mkdir -p coverage || true; mv coverage_tmp coverage/coverage_${e}_${p}_flutter || true; fi)
				else
					(cd "$PKG_DIR" && flutter test --dart-define=DZ_PLATFORM=$p --dart-define=DZ_ENV=$e --coverage) || true
					(cd "$PKG_DIR" && if [ -d coverage ]; then mv coverage coverage_tmp || true; mkdir -p coverage || true; mv coverage_tmp coverage/coverage_${e}_${p}_flutter || true; fi)
				fi
			else
				if [ "$p" = "web" ]; then
					(cd "$PKG_DIR" && dart --define=DZ_ENV=$e --define=DZ_PLATFORM=$p test -p chrome --coverage=coverage/coverage_${e}_${p}_dart) || true
				else
					(cd "$PKG_DIR" && dart --define=DZ_ENV=$e --define=DZ_PLATFORM=$p test --coverage=coverage/coverage_${e}_${p}_dart) || true
				fi
			fi
		done
	done
done

echo "Converting and aggregating coverage..."
cd "$ROOT_DIR"
bash scripts/compute_local_coverage.sh
bash scripts/inventory_uncovered.sh

echo "Smoke collection complete. Inventory: scripts/coverage_uncovered.csv"

exit 0
