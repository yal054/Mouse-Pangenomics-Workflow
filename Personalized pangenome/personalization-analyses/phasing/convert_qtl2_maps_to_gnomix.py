#!/usr/bin/env python3
"""
Convert R/qtl2 MMnGM gmap/pmap CSV files to gnomix .gmap format.

Usage:
    python3 convert_qtl2_maps_to_gnomix.py gmap_MMnGM.csv pmap_MMnGM.csv output_dir/

Input CSVs (R/qtl2 format, one row per marker):
    Long format:  marker,chr,pos  (pos in cM for gmap, Mbp for pmap)
    Wide format:  marker,1,2,...,19,X  (values = positions, blanks for other chrs)

Output: one file per chromosome in output_dir/ named chr{N}.mouse.gmap
    gnomix format (tab-delimited with header):
        chrom   pos   pos_cm
    where pos is in bp (integer) and pos_cm is cumulative cM.
"""

import sys
import os
import csv


def read_qtl2_map(path):
    """
    Read R/qtl2 gmap or pmap CSV.
    Returns dict: {chr_name: [(marker_id, pos_float), ...]} sorted by pos.
    """
    data = {}
    with open(path, newline='') as f:
        reader = csv.reader(f)
        header = next(reader)
        header = [h.strip() for h in header]

        if len(header) >= 3 and header[1].lower() in ('chr', 'chrom', 'chromosome'):
            # Long format: marker, chr, pos
            for row in reader:
                if len(row) < 3:
                    continue
                marker = row[0].strip()
                chr_ = row[1].strip()
                pos_str = row[2].strip()
                if not pos_str:
                    continue
                try:
                    pos = float(pos_str)
                except ValueError:
                    continue
                data.setdefault(chr_, []).append((marker, pos))
        else:
            # Wide format: first col = marker ID, remaining cols = chromosomes
            chrs = header[1:]
            for row in reader:
                if not row:
                    continue
                marker = row[0].strip()
                for i, chr_ in enumerate(chrs):
                    val = row[i + 1].strip() if i + 1 < len(row) else ''
                    if not val:
                        continue
                    try:
                        pos = float(val)
                        data.setdefault(chr_, []).append((marker, pos))
                    except ValueError:
                        continue

    for chr_ in data:
        data[chr_].sort(key=lambda x: x[1])

    return data


def chr_sort_key(c):
    """Sort chr1..chr19, chrX, chrY, chrM in natural order."""
    name = c.replace('chr', '').replace('Chr', '')
    try:
        return (int(name), name)
    except ValueError:
        order = {'X': 20, 'x': 20, 'Y': 21, 'y': 21, 'M': 22, 'm': 22}
        return (order.get(name, 99), name)


def main():
    if len(sys.argv) != 4:
        print(__doc__)
        sys.exit(1)

    gmap_path, pmap_path, out_dir = sys.argv[1], sys.argv[2], sys.argv[3]
    os.makedirs(out_dir, exist_ok=True)

    print(f"Reading genetic map (cM): {gmap_path}")
    gmap = read_qtl2_map(gmap_path)
    print(f"  Chromosomes found: {sorted(gmap.keys(), key=chr_sort_key)}")
    for c in sorted(gmap.keys(), key=chr_sort_key):
        print(f"    {c}: {len(gmap[c])} markers")

    print(f"Reading physical map (Mbp): {pmap_path}")
    pmap = read_qtl2_map(pmap_path)
    print(f"  Chromosomes found: {sorted(pmap.keys(), key=chr_sort_key)}")

    chrs = sorted(set(gmap.keys()) & set(pmap.keys()), key=chr_sort_key)
    print(f"Processing {len(chrs)} chromosomes present in both maps...")

    for chr_ in chrs:
        gpos = {m: cm for m, cm in gmap[chr_]}
        ppos = {m: mbp * 1e6 for m, mbp in pmap[chr_]}

        common = sorted(
            [(m, int(round(ppos[m])), gpos[m]) for m in gpos if m in ppos],
            key=lambda x: x[1]
        )

        if len(common) < 2:
            print(f"  WARNING: {chr_} has fewer than 2 common markers -- skipping")
            continue

        # Use chr-prefixed names to match VCF CHROM field
        out_chr = chr_ if chr_.startswith('chr') else f'chr{chr_}'
        out_path = os.path.join(out_dir, f'{out_chr}.mouse.gmap')

        with open(out_path, 'w') as f:
            f.write("chrom\tpos\tpos_cm\n")
            for marker, bp, cm in common:
                # gnomix expects chromosome as number or name without chr prefix
                # but here we match the full chr name in the VCF CHROM field
                f.write(f"{out_chr}\t{bp}\t{cm:.6f}\n")

        print(f"  {out_chr}: {len(common)} markers -> {out_path}")

    print("Done.")


if __name__ == '__main__':
    main()
