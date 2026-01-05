#!/usr/bin/env bash
# Generate CSV of uncovered lines per package/file from LCOVs (excluding example/generated)
set -euo pipefail

OUT="scripts/coverage_uncovered.csv"
rm -f "$OUT"

echo "package,file,missed_lines" > "$OUT"

# find filtered lcov files
# find and iterate lcov files (exclude example/generated)
found=0
while IFS= read -r -d '' f; do
  found=1
  pkg_from_path=$(echo "$f" | awk -F"/" '{print $2}')
  awk -v PKG="$pkg_from_path" '
    BEGIN{missed=0; pkg=PKG; file=""}
    /^SF:/ {
      if (pkg!="" && missed>0) print pkg","file","missed;
      split($0,a,":"); full=a[2];
      # file path relative to package: everything after "/lib/"
      libpos = index(full, "/lib/");
      if (libpos>0) file = substr(full, libpos+1); else file = full;
      missed=0;
      next
    }
    /^DA:/ {
      split($0,a,":"); split(a[2],c,","); hits = c[2]+0; if (hits==0) missed++;
    }
    END { if (pkg!="" && missed>0) print pkg","file","missed }
  ' "$f" >> "$OUT"
done < <(find packages -maxdepth 6 -type f -name "lcov*.info" \( -not -path '*/example/*' -a -not -path '*/generated/*' \) -print0 2>/dev/null)

if [ "$found" -eq 0 ]; then
  echo "No lcov.info files found (excluded example/generated)."
  exit 1
fi

echo "Wrote $OUT"
exit 0
