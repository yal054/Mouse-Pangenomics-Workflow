#!/usr/bin/env bash
set -euo pipefail

REF_FAI="GRCm38.p6.renamed.filtered.fa.fai"

awk -v fai="$REF_FAI" '
BEGIN {
    FS = OFS = "\t"
    while ((getline < fai) > 0) {
        len[$1] = $2
    }
    close(fai)
}

/^@SQ/ {
    sn = ""

    for (i = 1; i <= NF; i++) {
        if ($i ~ /^SN:/) {
            sn = substr($i, 4)
            break
        }
    }

    if (sn == "") {
        print "ERROR: @SQ line missing SN tag: " $0 > "/dev/stderr"
        exit 1
    }

    if (!(sn in len)) {
        print "ERROR: sequence " sn " not found in " fai > "/dev/stderr"
        exit 1
    }

    for (i = 1; i <= NF; i++) {
        if ($i ~ /^LN:/) {
            $i = "LN:" len[sn]
            break
        }
    }
}

{ print }
'
