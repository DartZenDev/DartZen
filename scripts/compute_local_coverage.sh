#!/usr/bin/env bash
# Compute per-package and aggregate coverage from lcov.info files under packages/
set -euo pipefail

# Ensure per-package LCOV exists by converting any VM JSON coverage under
# `packages/*/coverage` and any nested `apps/*/.../coverage` into per-package
# `coverage/lcov_*.info`. This scans packages and apps recursively for
# coverage directories so app-level vm.json artifacts are converted too.
converted_global=()
while IFS= read -r -d '' cov_root; do
  # cov_root is a .../coverage directory; the package/app directory is its parent
  pkgdir=$(dirname "$cov_root")
  converted=()
  for cov in "$cov_root" "$cov_root"/coverage_*; do
    if [ -d "$cov/test" ]; then
      cov_base=$(basename "$cov")
      out="$pkgdir/coverage/lcov_${cov_base}.info"

      # Determine whether to convert VM JSON -> LCOV. If a coverage/lcov.info
      # already exists and is newer than the newest vm.json file, skip conversion for this run.
      convert=true
      if [ -f "$pkgdir/coverage/lcov.info" ]; then
        vm_count=$(find "$cov/test" -type f -name "*.vm.json" 2>/dev/null | wc -l || echo 0)
        if [ "$vm_count" -gt 0 ]; then
          newest_vm_json_mtime=$(find "$cov/test" -type f -name "*.vm.json" -print0 | xargs -0 stat -f "%m" 2>/dev/null | sort -n | tail -1 || echo 0)
        else
          newest_vm_json_mtime=0
        fi
        lcov_mtime=$(stat -f "%m" "$pkgdir/coverage/lcov.info" 2>/dev/null || echo 0)
        if [ -n "$lcov_mtime" ] && [ "$lcov_mtime" -ge "$newest_vm_json_mtime" ]; then
          echo "Skipping conversion for $cov: existing coverage/lcov.info is newer than vm.json files"
          convert=false
        fi
      fi

      if [ "$convert" = true ]; then
        echo "Converting JSON coverage -> LCOV for $cov"
        rel_cov=${cov#${pkgdir}/}
        rel_out=${out#${pkgdir}/}
        (cd "$pkgdir" && dart pub global run coverage:format_coverage \
          --package="." --report-on="lib" --lcov --in="$rel_cov/test" --out="$rel_out" ) || true
      fi

      if [ -f "$out" ]; then
        converted+=("$out")
        converted_global+=("$out")
        # cleanup VM JSON artifacts for this run
        if [ -d "$cov/test" ]; then
          find "$cov/test" -type f -name "*.vm.json" -print -delete || true
          rmdir "$cov/test" 2>/dev/null || true
        fi
      fi
    fi
  done

  # Merge converted per-run lcovs into a single lcov.info for the package
  if [ ${#converted[@]} -gt 0 ]; then
    pkg_lcov="$pkgdir/coverage/lcov.info"
    cat ${converted[@]} > "$pkg_lcov" || true
    package=$(basename "$pkgdir")
    if sed -i "s|SF:lib/|SF:packages/$package/lib/|g" "$pkg_lcov" 2>/dev/null; then
      :
    else
      sed -i '' "s|SF:lib/|SF:packages/$package/lib/|g" "$pkg_lcov" 2>/dev/null || true
    fi
    awk '!/^SF:.*\/(test|example)\// && !/^SF:.*\/generated\//' "$pkg_lcov" > "$pkgdir/coverage/lcov.info.filtered" && mv "$pkgdir/coverage/lcov.info.filtered" "$pkg_lcov" || true
  fi
done < <(find packages apps -type d -name coverage -print0 2>/dev/null || true)

find_lcov() {
  # find lcov.info under packages/ and apps/, but exclude example and generated directories
  find packages apps -type f -name "lcov*.info" \( -not -path '*/example/*' -a -not -path '*/generated/*' \) 2>/dev/null || true
}

files=$(find_lcov)
if [ -z "$files" ]; then
  echo "No lcov.info files found under packages/"
  exit 1
fi

total_cov=0
total_loc=0

# temporary results file
TMP_RESULTS=$(mktemp)

# Iterate packages and apps directory-wise to merge multiple lcov files per package/app
for pkgdir in packages/* apps/*; do
  [ -d "$pkgdir" ] || continue
  pkg=$(basename "$pkgdir")
  # collect lcov files for this package/app
  pkg_lcovs=()
  if [[ "$pkgdir" == apps/* ]]; then
    # For apps, lcov files may be nested under subpackages; search recursively
    while IFS= read -r -d '' f; do pkg_lcovs+=("$f"); done < <(find "$pkgdir" -type f -name "lcov*.info" -print0 2>/dev/null || true)
  else
    # For packages, look in the package's coverage directory only
    if [ -d "$pkgdir/coverage" ]; then
      # collect any lcov files under the package's coverage directory, including nested per-run dirs
      while IFS= read -r -d '' f; do pkg_lcovs+=("$f"); done < <(find "$pkgdir/coverage" -type f -name "lcov*.info" -print0 2>/dev/null || true)
    fi
  fi
  if [ ${#pkg_lcovs[@]} -eq 0 ]; then
    continue
  fi

  # Merge DA entries across all lcov files: for each source file+line keep the max hit value
  # awk will output combined per-file totals
  read cov loc < <(
    awk '
      BEGIN { OFS = " " }
      /^SF:/ { sf = substr($0,4); next }
      /^DA:/ {
        split($0,a,":"); split(a[2],b,","); line = b[1]; hits = b[2] + 0; key = sf "|" line;
        if (key in max) { if (hits > max[key]) max[key] = hits } else max[key] = hits;
        next
      }
      END {
        # compute total and covered by source file
        for (k in max) {
          split(k, parts, "|"); file = parts[1]; total[file]++; if (max[k] > 0) covered[file]++;
        }
        c = 0; t = 0; for (f in total) { c += covered[f] + 0; t += total[f] + 0 }
        print c, t
      }
    ' "${pkg_lcovs[@]}"
  )

  cov=${cov:-0}
  loc=${loc:-0}
  pct=$(awk -v c="$cov" -v t="$loc" 'BEGIN{if(t==0) printf("0.00"); else printf("%.2f", c/t*100)}')
  # store results to temp file for sorting later: pkg|cov|loc|pct_numeric
  echo "$pkg|$cov|$loc|$pct" >> "$TMP_RESULTS"
  total_cov=$((total_cov + cov))
  total_loc=$((total_loc + loc))
done
# Print header and rows. If no packages produced results, show a placeholder.
if [ ! -s "$TMP_RESULTS" ]; then
  printf "%-40s %10s %10s %10s\n" "Package" "Covered" "Total" "Pct"
  printf "%-40s %10s %10s %10s\n" "-------" "-------" "-----" "---"
  printf "%-40s %10s %10s %10s\n" "No coverage data" "-" "-" "-"
else
  printf "%-40s %10s %10s %10s\n" "Package" "Covered" "Total" "Pct"
  printf "%-40s %10s %10s %10s\n" "-------" "-------" "-----" "---"

  # Sort results by pct (numeric) descending and print
  sort -t'|' -k4 -nr "$TMP_RESULTS" | while IFS='|' read -r pkg cov loc pct; do
    printf "%-40s %10d %10d %9s%%\n" "$pkg" "$cov" "$loc" "$pct"
  done
fi

agg_pct=$(awk -v c="$total_cov" -v t="$total_loc" 'BEGIN{if(t==0) printf("0.00"); else printf("%.2f", c/t*100)}')
printf "\n%-40s %10d %10d %9s%%\n" "AGGREGATE" "$total_cov" "$total_loc" "$agg_pct"

echo
echo "LOCAL_COVERAGE=$agg_pct"

rm -f "$TMP_RESULTS"

exit 0
