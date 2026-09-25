#!/usr/bin/env python3
# Local setup: replace every /path/to placeholder below before running.
# /path/to/mosaic_haplotypes: directory containing the CC mosaic haplotype .hap files.
"""Parse CC .hap files and compute haplotype block length distribution."""
import glob, sys
import numpy as np

hapl_dir = "/path/to/mosaic_haplotypes"

lengths_bp = []

for fpath in sorted(glob.glob(f"{hapl_dir}/*.hap")):
    with open(fpath) as f:
        for line in f:
            line = line.strip()
            if not line.startswith("chr"):
                continue
            fields = line.split(",")
            # fields: chr, (empty), founder, start, end, founder, start, end, ...
            # blocks start at index 2, every 3 fields
            i = 2
            while i + 2 < len(fields):
                founder = fields[i]
                try:
                    start = int(fields[i+1])
                    end   = int(fields[i+2])
                    length = end - start
                    if length > 0:
                        lengths_bp.append(length)
                except ValueError:
                    pass
                i += 3

lengths_bp = np.array(lengths_bp)
lengths_mb = lengths_bp / 1e6

# 1 cM ~ 2 Mb in mouse
lengths_cm = lengths_mb / 2.0

print(f"Total blocks: {len(lengths_bp):,}")
print(f"\n--- Block length (Mb) ---")
pcts = [1, 5, 10, 25, 50, 75, 90, 95, 99]
for p in pcts:
    print(f"  p{p:2d}: {np.percentile(lengths_mb, p):.2f} Mb  (~{np.percentile(lengths_cm, p):.2f} cM)")
print(f"  mean: {lengths_mb.mean():.2f} Mb  (~{lengths_cm.mean():.2f} cM)")
print(f"  median: {np.median(lengths_mb):.2f} Mb  (~{np.median(lengths_cm):.2f} cM)")

print(f"\n--- Histogram (Mb) ---")
bins = [0, 1, 2, 5, 10, 20, 50, 100, 200]
counts, _ = np.histogram(lengths_mb, bins=bins)
for i in range(len(counts)):
    bar = "#" * int(counts[i] / max(counts) * 40)
    print(f"  {bins[i]:>3}-{bins[i+1]:<3} Mb: {counts[i]:>5}  {bar}")
