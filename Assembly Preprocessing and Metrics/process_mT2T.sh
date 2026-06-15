#!/usr/bin/env bash
# normalize_chr.sh
#
# Lowercases "C", strips any leading zeros, and prefixes "chr".
# Usage: ./normalize_chr.sh input.fasta > output.fasta

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <input.fasta>" >&2
  exit 1
fi

sed -E 's/^>Chr0*([0-9]+|X|M|Y)/>chr\1/' "$1"

