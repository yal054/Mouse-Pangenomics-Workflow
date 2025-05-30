import pandas as pd
import os
import sys
import subprocess  # For bedtools

DATA = '/path/to/data'  # Adjust this to your root data directory

# Define valid chromosomes for human and mouse
valid_chroms_dict = {
    'mouse': ['chr' + str(i) for i in range(1, 20)] + ['chrX', 'chrY']
}

# Define blacklist file paths
blacklist_files = {
    'mouse': os.path.join(DATA, '7.genome', 'mm10-blacklist.v2.bed'),
}

def process_macs2_peaks(peak_file, species, valid_chroms, blacklist_file):
    """Processes peak files, removes blacklist overlaps, filters by SPM ≥ 1."""
    print(f"Processing {peak_file}...")

    col_names = ["chrom", "start", "end", "name", "score"]

    # Remove blacklist overlaps
    peaks_filtered = remove_blacklist_overlap(peak_file, blacklist_file)

    # Load filtered peaks
    peaks = pd.read_csv(peaks_filtered, sep="\t", names=col_names, usecols=[0, 1, 2, 3, 4])
    peaks = peaks[peaks["chrom"].isin(valid_chroms)]

    # Normalize scores & apply SPM filtering
    peaks['score'] = peaks['score'].clip(upper=1000)
    total_score = peaks["score"].sum()
    peaks["spm"] = (peaks["score"] / total_score) * 1e6
    peaks = peaks[peaks["spm"] >= 1]

    return peaks

def remove_blacklist_overlap(peak_file, blacklist_file):
    """Removes peaks that overlap blacklist regions using bedtools."""
    print(f"Removing blacklist overlaps using {blacklist_file}...")

    temp_peak_file = f"{peak_file}_filtered"

    # Use bedtools intersect to remove overlaps
    cmd = f"bedtools intersect -v -a {peak_file} -b {blacklist_file} > {temp_peak_file}"
    subprocess.run(cmd, shell=True, check=True)

    return temp_peak_file

def ensure_directory_exists(path):
    """Ensures the output directory exists."""
    if not os.path.exists(path):
        os.makedirs(path)

def main():
    if len(sys.argv) < 3:
        print("Usage: python script.py [peak_file] [output_dir]")
        sys.exit(1)

    species = 'mouse'
    peak_file = sys.argv[1]
    output_dir = sys.argv[2]

    prefix = os.path.splitext(os.path.basename(peak_file))[0]
    blacklist_file = blacklist_files.get(species)
    valid_chroms = valid_chroms_dict.get(species, [])

    ensure_directory_exists(output_dir)

    filtered_peaks = process_macs2_peaks(peak_file, species, valid_chroms, blacklist_file)

    output_path = os.path.join(output_dir, f'{prefix}_summits_extend.bed')
    filtered_peaks.to_csv(output_path, sep='\t', index=False, header=False)

    print(f"Filtered peaks saved to {output_path}")

if __name__ == '__main__':
    main()