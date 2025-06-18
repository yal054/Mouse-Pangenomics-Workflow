#!/usr/bin/env bash
# Adds "chr" in front of numeric, X or M chromosome IDs in FASTA headers.

sed -E 's/^>([0-9]+|X|M)/>chr\1/' "$1"

