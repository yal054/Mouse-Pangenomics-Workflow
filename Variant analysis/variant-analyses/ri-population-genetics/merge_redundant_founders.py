#!/usr/bin/env python3
"""
Collapse multiple assemblies of the same founder strain into one column.

The pangenome carries more than one assembly for some strains: three for
C57BL/6 and two for CAST/EiJ. For allele-sharing and population-structure
analysis those must be collapsed, or a strain with more assemblies is
over-weighted.

A merged column is 1 if the allele is present in ANY of the member assemblies.
The merged column takes the position of its anchor column, so column order is
otherwise preserved.

Usage:
    merge_redundant_founders.py <presence_absence.txt> <output.txt>
"""
import sys

MERGE_SPECS = [
    {
        "out_name": "C57BL_6",
        "cols": ["C57BL_6J_T2T_Keane", "C57BL_6_T2T_Yu", "GRCm39"],
        "anchor": "C57BL_6J_T2T_Keane",
    },
    {
        "out_name": "CAST_EiJ",
        "cols": ["CAST_EiJ", "CAST_EiJ_T2T_Keane"],
        "anchor": "CAST_EiJ",
    },
]


def merged_value(fields, idx, cols):
    return "1" if any(fields[idx[c]] == "1" for c in cols) else "0"


def main():
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    infile, outfile = sys.argv[1], sys.argv[2]

    with open(infile) as fin, open(outfile, "w") as fout:
        header = fin.readline().rstrip("\n").split("\t")
        idx = {c: i for i, c in enumerate(header)}

        missing = []
        for spec in MERGE_SPECS:
            for c in spec["cols"] + [spec["anchor"]]:
                if c not in idx:
                    missing.append(c)
        if missing:
            raise SystemExit("Missing columns: " + ", ".join(sorted(set(missing))))

        # per-column action: keep, drop, or become the merged column
        action = {c: ("keep", None) for c in header}
        for spec in MERGE_SPECS:
            action[spec["anchor"]] = ("merge", spec)
            for c in spec["cols"]:
                if c != spec["anchor"]:
                    action[c] = ("drop", spec)

        new_header = []
        for c in header:
            kind, spec = action[c]
            if kind == "drop":
                continue
            new_header.append(spec["out_name"] if kind == "merge" else c)
        fout.write("\t".join(new_header) + "\n")

        for line in fin:
            fields = line.rstrip("\n").split("\t")
            merged_vals = {
                spec["out_name"]: merged_value(fields, idx, spec["cols"])
                for spec in MERGE_SPECS
            }
            out_fields = []
            for c in header:
                kind, spec = action[c]
                if kind == "drop":
                    continue
                if kind == "merge":
                    out_fields.append(merged_vals[spec["out_name"]])
                else:
                    out_fields.append(fields[idx[c]])
            fout.write("\t".join(out_fields) + "\n")

    print("Wrote:", outfile)


if __name__ == "__main__":
    main()
