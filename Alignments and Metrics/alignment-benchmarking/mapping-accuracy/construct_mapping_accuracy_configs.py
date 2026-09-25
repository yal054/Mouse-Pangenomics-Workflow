#!/usr/bin/env python3
# Local setup: replace every /path/to placeholder below before running.
# /path/to/refract: refract executable.
# /path/to/run_check_jobs_with_reportseff.sh: external Slurm job-monitoring helper (not included).
"""
Generate YAML configs and snakemake parameter file for mapping accuracy pipeline.

Input: tab-delimited file with columns:
    BAM  RG1  PAF1  RG2  PAF2

Output:
    - Per row: {bam_stem}.yaml
    - Snakemake parameter file: {output_prefix}_parameters.txt
"""

import argparse
import os
import sys
import yaml


FIXED_CONFIG = {
    "refract": {
        "bin": "/path/to/refract",
        "q": 5,
        "l": 50000,
        "d": 1,
    },
    # spack specs for the builds used in the original analysis (tool@version/build-hash);
    # change these to match how you install samtools, bedtools and gcc.
    "spack": {
        "samtools": "samtools@1.13/5dgya4q",
        "bedtools": "bedtools2@2.30.0/f3mnrck",
        "gcc": "gcc@11.2.0",
    },
    "scripts": {
        "check_jobs": "/path/to/run_check_jobs_with_reportseff.sh",
    },
}


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input", help="Tab-delimited parameter file (BAM RG1 PAF1 RG2 PAF2)")
    parser.add_argument("-o", "--output-dir", default=".", help="Directory for YAML outputs (default: current)")
    parser.add_argument("-p", "--param-file", default="Mapping_Accuracy_SnakeMake_Parameters.txt",
                        help="Output snakemake parameter file name")
    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)

    param_lines = []

    with open(args.input) as fh:
        for lineno, line in enumerate(fh, 1):
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            fields = line.split("\t")
            if len(fields) != 5:
                print(f"ERROR line {lineno}: expected 5 tab-delimited fields, got {len(fields)}", file=sys.stderr)
                sys.exit(1)

            bam, rg1, paf1, rg2, paf2 = fields
            bam_stem = os.path.splitext(os.path.basename(bam))[0]

            # Validate inputs exist
            if not os.path.exists(bam):
                print(f"WARNING line {lineno}: BAM not found: {bam}", file=sys.stderr)
            if not os.path.exists(paf1):
                print(f"WARNING line {lineno}: PAF index not found: {paf1}", file=sys.stderr)
            if not os.path.exists(paf2):
                print(f"WARNING line {lineno}: PAF index not found: {paf2}", file=sys.stderr)

            config = {
                "bam": bam,
                "read_groups": {
                    rg1: paf1,
                    rg2: paf2,
                },
            }
            config.update(FIXED_CONFIG)

            yaml_path = os.path.join(args.output_dir, f"{bam_stem}.yaml")
            with open(yaml_path, "w") as yf:
                yaml.dump(config, yf, default_flow_style=False, sort_keys=False)
            print(f"Created: {yaml_path}")

            workdir = bam_stem
            yaml_abspath = os.path.abspath(yaml_path)
            param_lines.append(f"{workdir}\t{yaml_abspath}")

    param_path = os.path.join(args.output_dir, args.param_file)
    with open(param_path, "w") as pf:
        pf.write("\n".join(param_lines) + "\n")
    print(f"Created: {param_path} ({len(param_lines)} entries)")


if __name__ == "__main__":
    main()