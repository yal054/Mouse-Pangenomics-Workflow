#!/bin/bash




fastqc -o ./step4.qc/SRX2175958/fastqc_1/ -t 1 ./step1.raw/SRX2175958_R1.fq ./step1.raw/SRX2175958_R2.fq     > ./step4.qc/SRX2175958/fastqc_1/qc.out 2> ./step4.qc/SRX2175958/fastqc_1/qc.err
fastqc -o ./step4.qc/SRX2175958/fastqc_2/ -t 1 ./step2.trim/SRX2175958_R1.fq ./step2.trim/SRX2175958_R2.fq   > ./step4.qc/SRX2175958/fastqc_2/qc.out 2> ./step4.qc/SRX2175958/fastqc_2/qc.err
fastqc -o ./step4.qc/SRX2175958/fastqc_3/ -t 1 ./step3.dedup/SRX2175958_R1.fq ./step3.dedup/SRX2175958_R2.fq > ./step4.qc/SRX2175958/fastqc_3/qc.out 2> ./step4.qc/SRX2175958/fastqc_3/qc.err




fastqc -o ./step4.qc/SRX2175959/fastqc_1/ -t 1 ./step1.raw/SRX2175959_R1.fq ./step1.raw/SRX2175959_R2.fq     > ./step4.qc/SRX2175959/fastqc_1/qc.out 2> ./step4.qc/SRX2175959/fastqc_1/qc.err
fastqc -o ./step4.qc/SRX2175959/fastqc_2/ -t 1 ./step2.trim/SRX2175959_R1.fq ./step2.trim/SRX2175959_R2.fq   > ./step4.qc/SRX2175959/fastqc_2/qc.out 2> ./step4.qc/SRX2175959/fastqc_2/qc.err
fastqc -o ./step4.qc/SRX2175959/fastqc_3/ -t 1 ./step3.dedup/SRX2175959_R1.fq ./step3.dedup/SRX2175959_R2.fq > ./step4.qc/SRX2175959/fastqc_3/qc.out 2> ./step4.qc/SRX2175959/fastqc_3/qc.err




fastqc -o ./step4.qc/SRX2175960/fastqc_1/ -t 1 ./step1.raw/SRX2175960_R1.fq ./step1.raw/SRX2175960_R2.fq     > ./step4.qc/SRX2175960/fastqc_1/qc.out 2> ./step4.qc/SRX2175960/fastqc_1/qc.err
fastqc -o ./step4.qc/SRX2175960/fastqc_2/ -t 1 ./step2.trim/SRX2175960_R1.fq ./step2.trim/SRX2175960_R2.fq   > ./step4.qc/SRX2175960/fastqc_2/qc.out 2> ./step4.qc/SRX2175960/fastqc_2/qc.err
fastqc -o ./step4.qc/SRX2175960/fastqc_3/ -t 1 ./step3.dedup/SRX2175960_R1.fq ./step3.dedup/SRX2175960_R2.fq > ./step4.qc/SRX2175960/fastqc_3/qc.out 2> ./step4.qc/SRX2175960/fastqc_3/qc.err




fastqc -o ./step4.qc/SRX2175961/fastqc_1/ -t 1 ./step1.raw/SRX2175961_R1.fq ./step1.raw/SRX2175961_R2.fq     > ./step4.qc/SRX2175961/fastqc_1/qc.out 2> ./step4.qc/SRX2175961/fastqc_1/qc.err
fastqc -o ./step4.qc/SRX2175961/fastqc_2/ -t 1 ./step2.trim/SRX2175961_R1.fq ./step2.trim/SRX2175961_R2.fq   > ./step4.qc/SRX2175961/fastqc_2/qc.out 2> ./step4.qc/SRX2175961/fastqc_2/qc.err
fastqc -o ./step4.qc/SRX2175961/fastqc_3/ -t 1 ./step3.dedup/SRX2175961_R1.fq ./step3.dedup/SRX2175961_R2.fq > ./step4.qc/SRX2175961/fastqc_3/qc.out 2> ./step4.qc/SRX2175961/fastqc_3/qc.err


