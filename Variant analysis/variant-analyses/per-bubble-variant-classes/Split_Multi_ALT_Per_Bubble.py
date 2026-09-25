#!/usr/bin/env python3
"""
Split rows with multiple ALT alleles into separate rows, adding START and STOP.
Supports multiprocessing to process chunks in parallel for lower wall-time.
Removes duplicate CHROM column by excluding it from other_cols.
"""
import argparse
import csv
import multiprocessing as mp

# Globals for worker processes
LIST_COLS = None
LIST_COLS_INDICES = None
OTHER_COLS = None
OTHER_INDICES = None
CHROM_I = None
POS_I = None
REF_LEN_I = None
LIST_COLS_SET = None


def init_worker(list_cols, list_cols_idx, other_cols, other_idx,
                chrom_i, pos_i, ref_i):
    global LIST_COLS, LIST_COLS_INDICES, OTHER_COLS, OTHER_INDICES
    global CHROM_I, POS_I, REF_LEN_I, LIST_COLS_SET
    LIST_COLS = list_cols
    LIST_COLS_INDICES = list_cols_idx
    OTHER_COLS = other_cols
    OTHER_INDICES = other_idx
    CHROM_I = chrom_i
    POS_I = pos_i
    REF_LEN_I = ref_i
    LIST_COLS_SET = set(list_cols)


def process_line(row):
    chrom = row[CHROM_I]
    start = int(row[POS_I])
    ref_len = int(row[REF_LEN_I])
    stop = start + ref_len

    # Split list columns for this row
    splits = {col: row[idx].split(',') for col, idx in zip(LIST_COLS, LIST_COLS_INDICES)}
    n_alts = len(splits[LIST_COLS[0]])

    out_rows = []
    for i in range(n_alts):
        out = [chrom, start, stop]
        for col, idx in zip(OTHER_COLS, OTHER_INDICES):
            if col in LIST_COLS_SET:
                out.append(splits[col][i])
            else:
                out.append(row[idx])
        out_rows.append(out)
    return out_rows


def stream_split(infile, outfile, cpus, chunk_size=10000):
    # Determine column indices from header
    with open(infile, 'r', newline='') as fin:
        reader = csv.reader(fin, delimiter='\t')
        hdr = next(reader)
    col_index = {c: i for i, c in enumerate(hdr)}
    chrom_i   = col_index['CHROM']
    pos_i     = col_index['POS']
    ref_len_i = col_index['REF_LEN']

    # Exclude POS and CHROM from other columns to avoid duplication
    other_cols = [c for c in hdr if c not in ('POS', 'CHROM')]
    other_indices = [col_index[c] for c in other_cols]

    list_cols = ['ALT_LENS', 'ALT_NS', 'ALT_MISSING',
                 'LEN_DIFFS', 'VARIANT_CLASSES', 'N_EQUIV']
    list_cols_idx = [col_index[c] for c in list_cols]

    # New header: CHROM, START, STOP + other_cols
    new_hdr = ['CHROM', 'START', 'STOP'] + other_cols

    # Create pool
    pool = mp.Pool(processes=cpus,
                   initializer=init_worker,
                   initargs=(list_cols, list_cols_idx,
                             other_cols, other_indices,
                             chrom_i, pos_i, ref_len_i))
    try:
        with open(infile, 'r', newline='') as fin, \
             open(outfile, 'w', newline='') as fout:
            reader = csv.reader(fin, delimiter='\t')
            writer = csv.writer(fout, delimiter='\t')
            next(reader)  # skip header
            writer.writerow(new_hdr)

            chunk = []
            for row in reader:
                chunk.append(row)
                if len(chunk) >= chunk_size:
                    for rows in pool.map(process_line, chunk):
                        writer.writerows(rows)
                    chunk = []
            if chunk:
                for rows in pool.map(process_line, chunk):
                    writer.writerows(rows)
    finally:
        pool.close()
        pool.join()


def main():
    parser = argparse.ArgumentParser(
        description='Stream-split multi-ALT bubbles into single-ALT rows with START, STOP; supports multiprocessing.'
    )
    parser.add_argument('infile', help='Input TSV (from Assign_Variant_Classes_Per_Bubble.py)')
    parser.add_argument('-o', '--out', help='Output TSV file', default='split_per_bubble.tsv')
    parser.add_argument('--cpus', type=int, default=1,
                        help='Number of parallel worker processes')
    parser.add_argument('--chunk-size', type=int, default=10000,
                        help='Number of lines per processing chunk')
    args = parser.parse_args()

    stream_split(args.infile, args.out, args.cpus, args.chunk_size)

if __name__ == '__main__':
    main()
