#!/usr/bin/env python3

import argparse
import os
import shutil
import subprocess
import sys
from concurrent.futures import ProcessPoolExecutor, as_completed


def run_command(cmd):
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode != 0:
        raise RuntimeError(
            "Command failed:\n{}\n\nstdout:\n{}\n\nstderr:\n{}".format(
                " ".join(cmd), result.stdout, result.stderr
            )
        )
    return result


def get_contigs(vcf_path):
    cmd = ["bcftools", "index", "-s", vcf_path]
    result = run_command(cmd)

    contigs = []
    for line in result.stdout.strip().splitlines():
        if not line.strip():
            continue
        fields = line.split("\t")
        contigs.append(fields[0])

    if not contigs:
        raise RuntimeError("No contigs found in indexed VCF: {}".format(vcf_path))

    return contigs


def convert_gt_token(gt):
    gt = gt.strip()

    if gt != "" and set(gt) == {"."}:
        return ".|."

    if "/" in gt or "|" in gt:
        alleles = gt.replace("/", "|").split("|")
        if len(alleles) != 2:
            raise ValueError("Unexpected diploid-like GT token: {}".format(gt))
        if alleles[0] == "." or alleles[1] == ".":
            return ".|."
        if alleles[0] != alleles[1]:
            raise ValueError("Encountered heterozygous genotype that cannot be homozygized safely: {}".format(gt))
        return "{0}|{0}".format(alleles[0])

    if gt.isdigit():
        return "{0}|{0}".format(gt)

    raise ValueError("Unexpected GT token: {}".format(gt))


def convert_sample_field(sample_field, format_field):
    format_keys = format_field.split(":")
    sample_parts = sample_field.split(":")

    if not format_keys:
        return sample_field

    if format_keys[0] != "GT":
        raise ValueError("Expected GT to be first FORMAT field, found: {}".format(format_field))

    sample_parts[0] = convert_gt_token(sample_parts[0])
    return ":".join(sample_parts)


def process_contig(args):
    contig, infile, tempdir = args

    contig_vcf = os.path.join(tempdir, "{}.vcf".format(contig))
    contig_vcfgz = os.path.join(tempdir, "{}.vcf.gz".format(contig))

    view_cmd = ["bcftools", "view", "-r", contig, infile]
    view_proc = subprocess.Popen(view_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    try:
        with open(contig_vcf, "w") as fout:
            for line in view_proc.stdout:
                if line.startswith("##"):
                    fout.write(line)
                    continue

                if line.startswith("#CHROM"):
                    fout.write(line)
                    continue

                line = line.rstrip("\n")
                fields = line.split("\t")

                if len(fields) < 10:
                    fout.write(line + "\n")
                    continue

                format_field = fields[8]

                for i in range(9, len(fields)):
                    fields[i] = convert_sample_field(fields[i], format_field)

                fout.write("\t".join(fields) + "\n")

        stderr = view_proc.stderr.read()
        returncode = view_proc.wait()
        if returncode != 0:
            raise RuntimeError("bcftools view failed for {}:\n{}".format(contig, stderr))

        run_command(["bgzip", "-f", contig_vcf])
        run_command(["bcftools", "index", "-t", contig_vcfgz])

        return contig_vcfgz

    finally:
        if view_proc.stdout:
            view_proc.stdout.close()
        if view_proc.stderr:
            view_proc.stderr.close()


def main():
    parser = argparse.ArgumentParser(
        description="Convert haploid-style GT fields in a bgzipped indexed VCF to phased homozygous diploid GT fields in parallel by contig."
    )
    parser.add_argument("--infile", required=True, help="Input VCF.GZ")
    parser.add_argument("--outfile", required=True, help="Output VCF.GZ")
    parser.add_argument("--threads", type=int, default=4, help="Number of contigs to process in parallel")
    parser.add_argument("--tempdir", required=True, help="Temporary working directory")
    args = parser.parse_args()

    if not os.path.exists(args.infile):
        raise FileNotFoundError("Input file not found: {}".format(args.infile))

    if not os.path.exists(args.infile + ".tbi") and not os.path.exists(args.infile + ".csi"):
        raise FileNotFoundError("Input VCF must be indexed with tabix or CSI: {}".format(args.infile))

    if shutil.which("bcftools") is None:
        raise RuntimeError("bcftools not found in PATH")

    if shutil.which("bgzip") is None:
        raise RuntimeError("bgzip not found in PATH")

    os.makedirs(args.tempdir, exist_ok=True)

    contigs = get_contigs(args.infile)
    print("Found {} contigs.".format(len(contigs)), file=sys.stderr)

    jobs = [(contig, args.infile, args.tempdir) for contig in contigs]
    contig_outputs = {}

    with ProcessPoolExecutor(max_workers=args.threads) as executor:
        future_to_contig = {executor.submit(process_contig, job): job[0] for job in jobs}

        for future in as_completed(future_to_contig):
            contig = future_to_contig[future]
            outpath = future.result()
            contig_outputs[contig] = outpath
            print("Finished {}".format(contig), file=sys.stderr)

    ordered_outputs = [contig_outputs[c] for c in contigs]

    concat_cmd = ["bcftools", "concat", "-a", "-Oz", "-o", args.outfile] + ordered_outputs
    run_command(concat_cmd)
    run_command(["bcftools", "index", "-t", args.outfile])

    print("Wrote {}".format(args.outfile), file=sys.stderr)
    print("Wrote {}".format(args.outfile + ".tbi"), file=sys.stderr)


if __name__ == "__main__":
    main()