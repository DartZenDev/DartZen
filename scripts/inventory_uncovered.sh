#!/usr/bin/env bash
# Generate CSV of uncovered lines per package/file from LCOVs (excluding example/generated)
set -euo pipefail

OUT="scripts/coverage_uncovered.csv"
rm -f "$OUT"

echo "package,file,missed_lines" > "$OUT"

# Use per-package merged coverage files only (coverage/lcov.info) to avoid
# emitting per-run duplicates (lcov_*.info). This ensures each package/file
# appears once with the aggregated missed-line count.
found=0

# The merged lcov.info may contain multiple SF blocks (one per run). For
# accurate, de-duplicated missed-line counts, sum DA hits across the entire
# file per source-line and then emit one CSV row per source file with the
# number of lines that had 0 total hits.
for pkgdir in packages/*; do
  [ -d "$pkgdir" ] || continue
  pkg=$(basename "$pkgdir")
  # find any lcov files under the package's coverage directory (including nested per-run dirs)
  # but avoid descending into nested 'coverage' directories (coverage/coverage/...) which
  # can be created by previous merges and lead to extremely long paths. Prune any
  # 'coverage' directory at depth >= 2 so we only scan the initial coverage tree.
  lcovs=()
  if [ -d "$pkgdir/coverage" ]; then
    while IFS= read -r -d '' lf; do
      lcovs+=("$lf")
    done < <(find "$pkgdir/coverage" \( -type d -name 'coverage*' -mindepth 2 -prune \) -o -type f -name "lcov*.info" -print0 2>/dev/null || true)
  fi
  if [ ${#lcovs[@]} -eq 0 ]; then
    continue
  fi
  found=1
  # concatenate all lcovs for this package and aggregate DA hits per source-line
  tmp_concat=$(mktemp)
  for lf in "${lcovs[@]}"; do
    cat "$lf" >> "$tmp_concat" || true
  done
  awk -v PKG="$pkg" '
    BEGIN { pkg = PKG }
    /^SF:/ { sf = substr($0,4); next }
    /^DA:/ {
      split($0,a,":"); split(a[2],b,","); line = b[1]; hits = b[2]+0; key = sf "|" line; sum[key] += hits; next
    }
    END {
      for (k in sum) {
        split(k, parts, "|"); file = parts[1]; total_lines[file]++; if (sum[k] == 0) missed_lines[file]++;
      }
      for (file in total_lines) {
        libpos = index(file, "/lib/"); if (libpos>0) rel = substr(file, libpos+1); else rel = file;
        missed = missed_lines[file] + 0;
        if (missed > 0) print pkg "," rel "," missed;
      }
    }
  ' "$tmp_concat" >> "$OUT"
  rm -f "$tmp_concat"
done

if [ "$found" -eq 0 ]; then
  echo "No lcov.info files found (excluded example/generated)."
  exit 1
fi

echo "Wrote $OUT"
exit 0
