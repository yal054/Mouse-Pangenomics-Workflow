#!/usr/bin/env bash
set -euo pipefail

STATS_GLOB='/storage2/fs1/hprc/Active/johnegarza/MPRC/new_alignments/alns/linear/GRCm38/*.stats.txt'

median_from_stream() {
  awk '
    { a[++n] = $1 }
    END {
      if (n == 0) {
        print "No values found" > "/dev/stderr"
        exit 1
      }
      if (n % 2 == 1) {
        print a[(n + 1) / 2]
      } else {
        print (a[n / 2] + a[n / 2 + 1]) / 2
      }
    }
  '
}

avg_median=$(
  awk -F'\t' '/^SN\tinsert size average:/ { print $3 }' $STATS_GLOB \
    | sort -n \
    | median_from_stream
)

sd_median=$(
  awk -F'\t' '/^SN\tinsert size standard deviation:/ { print $3 }' $STATS_GLOB \
    | sort -n \
    | median_from_stream
)

echo "Median insert size average: $avg_median"
echo "Median insert size standard deviation: $sd_median"
