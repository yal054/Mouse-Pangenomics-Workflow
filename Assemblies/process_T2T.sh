#!/usr/bin/env bash
# Lowercases "C", strips any leading zeros, and prefixes "chr".

sed -E 's/^>Chr0*([0-9]+|X|M)/>chr\1/' "$1"

