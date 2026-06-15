#!/usr/bin/env bash
# prefix_chr.sh
#
# Adds "chr" in front of numeric, X or M chromosome IDs in FASTA headers.
# Usage: ./prefix_chr.sh input.fasta > output.fasta

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <input.fasta>" >&2
  exit 1
fi

sed -E 's/^>([0-9]+|X|M)/>chr\1/' "$1"

