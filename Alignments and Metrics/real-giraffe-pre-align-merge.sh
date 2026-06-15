#!/usr/bin/env bash
set -euo pipefail

sample="${1:?sample (e.g. CC001) required}"
list_dir="${2:?list_dir required}"
out_dir="${3:?out_dir required}"

merge_from_list() {
  local list_file="$1"
  local out_file="$2"

  if [[ ! -s "$list_file" ]]; then
    echo "ERROR: missing/empty list: $list_file" >&2
    exit 2
  fi

  mkdir -p "$(dirname "$out_file")"

  # Write directly to the destination (will be partial if job dies mid-run).
  : > "$out_file"

  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    if [[ ! -s "$f" ]]; then
      echo "ERROR: missing/empty input: $f" >&2
      exit 3
    fi
    cat "$f" >> "$out_file"
  done < "$list_file"

  echo "WROTE: $out_file"
}

merge_from_list "${list_dir}/${sample}_R1.list" "${out_dir}/${sample}_R1.fastq"
merge_from_list "${list_dir}/${sample}_R2.list" "${out_dir}/${sample}_R2.fastq"

