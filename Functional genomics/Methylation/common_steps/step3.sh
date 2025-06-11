#!/bin/bash




fastqc -o ./step4.qc/SRX2175962/fastqc_1/ -t 1 ./step1.raw/SRX2175962_R1.fq ./step1.raw/SRX2175962_R2.fq     > ./step4.qc/SRX2175962/fastqc_1/qc.out 2> ./step4.qc/SRX2175962/fastqc_1/qc.err
fastqc -o ./step4.qc/SRX2175962/fastqc_2/ -t 1 ./step2.trim/SRX2175962_R1.fq ./step2.trim/SRX2175962_R2.fq   > ./step4.qc/SRX2175962/fastqc_2/qc.out 2> ./step4.qc/SRX2175962/fastqc_2/qc.err
fastqc -o ./step4.qc/SRX2175962/fastqc_3/ -t 1 ./step3.dedup/SRX2175962_R1.fq ./step3.dedup/SRX2175962_R2.fq > ./step4.qc/SRX2175962/fastqc_3/qc.out 2> ./step4.qc/SRX2175962/fastqc_3/qc.err




fastqc -o ./step4.qc/SRX2175963/fastqc_1/ -t 1 ./step1.raw/SRX2175963_R1.fq ./step1.raw/SRX2175963_R2.fq     > ./step4.qc/SRX2175963/fastqc_1/qc.out 2> ./step4.qc/SRX2175963/fastqc_1/qc.err
fastqc -o ./step4.qc/SRX2175963/fastqc_2/ -t 1 ./step2.trim/SRX2175963_R1.fq ./step2.trim/SRX2175963_R2.fq   > ./step4.qc/SRX2175963/fastqc_2/qc.out 2> ./step4.qc/SRX2175963/fastqc_2/qc.err
fastqc -o ./step4.qc/SRX2175963/fastqc_3/ -t 1 ./step3.dedup/SRX2175963_R1.fq ./step3.dedup/SRX2175963_R2.fq > ./step4.qc/SRX2175963/fastqc_3/qc.out 2> ./step4.qc/SRX2175963/fastqc_3/qc.err




fastqc -o ./step4.qc/SRX2175964/fastqc_1/ -t 1 ./step1.raw/SRX2175964_R1.fq ./step1.raw/SRX2175964_R2.fq     > ./step4.qc/SRX2175964/fastqc_1/qc.out 2> ./step4.qc/SRX2175964/fastqc_1/qc.err
fastqc -o ./step4.qc/SRX2175964/fastqc_2/ -t 1 ./step2.trim/SRX2175964_R1.fq ./step2.trim/SRX2175964_R2.fq   > ./step4.qc/SRX2175964/fastqc_2/qc.out 2> ./step4.qc/SRX2175964/fastqc_2/qc.err
fastqc -o ./step4.qc/SRX2175964/fastqc_3/ -t 1 ./step3.dedup/SRX2175964_R1.fq ./step3.dedup/SRX2175964_R2.fq > ./step4.qc/SRX2175964/fastqc_3/qc.out 2> ./step4.qc/SRX2175964/fastqc_3/qc.err




fastqc -o ./step4.qc/SRX2175965/fastqc_1/ -t 1 ./step1.raw/SRX2175965_R1.fq ./step1.raw/SRX2175965_R2.fq     > ./step4.qc/SRX2175965/fastqc_1/qc.out 2> ./step4.qc/SRX2175965/fastqc_1/qc.err
fastqc -o ./step4.qc/SRX2175965/fastqc_2/ -t 1 ./step2.trim/SRX2175965_R1.fq ./step2.trim/SRX2175965_R2.fq   > ./step4.qc/SRX2175965/fastqc_2/qc.out 2> ./step4.qc/SRX2175965/fastqc_2/qc.err
fastqc -o ./step4.qc/SRX2175965/fastqc_3/ -t 1 ./step3.dedup/SRX2175965_R1.fq ./step3.dedup/SRX2175965_R2.fq > ./step4.qc/SRX2175965/fastqc_3/qc.out 2> ./step4.qc/SRX2175965/fastqc_3/qc.err


