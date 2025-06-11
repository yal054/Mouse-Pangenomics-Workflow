#!/bin/bash


trim_galore --dont_gzip -q 20 --phred33 --illumina --stringency 1 -e 0.1 --length 20 --clip_R1 10 --clip_R2 15 -o ./ -j 10 --paired ./step1.raw/SRX2175958_R1.fq ./step1.raw/SRX2175958_R2.fq > ./step2.trim/SRX2175958_trim.log 2> ./step2.trim/SRX2175958_trim.err


mv ./SRX2175958_R1_val_1.fq ./step2.trim/SRX2175958_R1.fq
mv ./SRX2175958_R2_val_2.fq ./step2.trim/SRX2175958_R2.fq

mv ./*_report.txt ./step2.trim/

trim_galore --dont_gzip -q 20 --phred33 --illumina --stringency 1 -e 0.1 --length 20 --clip_R1 10 --clip_R2 15 -o ./ -j 10 --paired ./step1.raw/SRX2175959_R1.fq ./step1.raw/SRX2175959_R2.fq > ./step2.trim/SRX2175959_trim.log 2> ./step2.trim/SRX2175959_trim.err


mv ./SRX2175959_R1_val_1.fq ./step2.trim/SRX2175959_R1.fq
mv ./SRX2175959_R2_val_2.fq ./step2.trim/SRX2175959_R2.fq

mv ./*_report.txt ./step2.trim/

trim_galore --dont_gzip -q 20 --phred33 --illumina --stringency 1 -e 0.1 --length 20 --clip_R1 10 --clip_R2 15 -o ./ -j 10 --paired ./step1.raw/SRX2175960_R1.fq ./step1.raw/SRX2175960_R2.fq > ./step2.trim/SRX2175960_trim.log 2> ./step2.trim/SRX2175960_trim.err


mv ./SRX2175960_R1_val_1.fq ./step2.trim/SRX2175960_R1.fq
mv ./SRX2175960_R2_val_2.fq ./step2.trim/SRX2175960_R2.fq

mv ./*_report.txt ./step2.trim/

trim_galore --dont_gzip -q 20 --phred33 --illumina --stringency 1 -e 0.1 --length 20 --clip_R1 10 --clip_R2 15 -o ./ -j 10 --paired ./step1.raw/SRX2175961_R1.fq ./step1.raw/SRX2175961_R2.fq > ./step2.trim/SRX2175961_trim.log 2> ./step2.trim/SRX2175961_trim.err


mv ./SRX2175961_R1_val_1.fq ./step2.trim/SRX2175961_R1.fq
mv ./SRX2175961_R2_val_2.fq ./step2.trim/SRX2175961_R2.fq

mv ./*_report.txt ./step2.trim/

