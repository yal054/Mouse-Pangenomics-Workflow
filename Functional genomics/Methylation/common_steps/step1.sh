#!/bin/bash


trim_galore --dont_gzip -q 20 --phred33 --illumina --stringency 1 -e 0.1 --length 20 --clip_R1 10 --clip_R2 15 -o ./ -j 10 --paired ./step1.raw/SRX2175962_R1.fq ./step1.raw/SRX2175962_R2.fq > ./step2.trim/SRX2175962_trim.log 2> ./step2.trim/SRX2175962_trim.err


mv ./SRX2175962_R1_val_1.fq ./step2.trim/SRX2175962_R1.fq
mv ./SRX2175962_R2_val_2.fq ./step2.trim/SRX2175962_R2.fq

mv ./*_report.txt ./step2.trim/

trim_galore --dont_gzip -q 20 --phred33 --illumina --stringency 1 -e 0.1 --length 20 --clip_R1 10 --clip_R2 15 -o ./ -j 10 --paired ./step1.raw/SRX2175963_R1.fq ./step1.raw/SRX2175963_R2.fq > ./step2.trim/SRX2175963_trim.log 2> ./step2.trim/SRX2175963_trim.err


mv ./SRX2175963_R1_val_1.fq ./step2.trim/SRX2175963_R1.fq
mv ./SRX2175963_R2_val_2.fq ./step2.trim/SRX2175963_R2.fq

mv ./*_report.txt ./step2.trim/

trim_galore --dont_gzip -q 20 --phred33 --illumina --stringency 1 -e 0.1 --length 20 --clip_R1 10 --clip_R2 15 -o ./ -j 10 --paired ./step1.raw/SRX2175964_R1.fq ./step1.raw/SRX2175964_R2.fq > ./step2.trim/SRX2175964_trim.log 2> ./step2.trim/SRX2175964_trim.err


mv ./SRX2175964_R1_val_1.fq ./step2.trim/SRX2175964_R1.fq
mv ./SRX2175964_R2_val_2.fq ./step2.trim/SRX2175964_R2.fq

mv ./*_report.txt ./step2.trim/

trim_galore --dont_gzip -q 20 --phred33 --illumina --stringency 1 -e 0.1 --length 20 --clip_R1 10 --clip_R2 15 -o ./ -j 10 --paired ./step1.raw/SRX2175965_R1.fq ./step1.raw/SRX2175965_R2.fq > ./step2.trim/SRX2175965_trim.log 2> ./step2.trim/SRX2175965_trim.err


mv ./SRX2175965_R1_val_1.fq ./step2.trim/SRX2175965_R1.fq
mv ./SRX2175965_R2_val_2.fq ./step2.trim/SRX2175965_R2.fq

mv ./*_report.txt ./step2.trim/

