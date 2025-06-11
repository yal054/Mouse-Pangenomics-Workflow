#!/bin/bash


fastuniq -i ./step3.dedup/SRX2175962_dedup_list.txt -o R1.dedup.fq -p R2.dedup.fq

mv ./R1.dedup.fq ./step3.dedup/SRX2175962_R1.fq
mv ./R2.dedup.fq ./step3.dedup/SRX2175962_R2.fq



fastuniq -i ./step3.dedup/SRX2175963_dedup_list.txt -o R1.dedup.fq -p R2.dedup.fq

mv ./R1.dedup.fq ./step3.dedup/SRX2175963_R1.fq
mv ./R2.dedup.fq ./step3.dedup/SRX2175963_R2.fq



fastuniq -i ./step3.dedup/SRX2175964_dedup_list.txt -o R1.dedup.fq -p R2.dedup.fq

mv ./R1.dedup.fq ./step3.dedup/SRX2175964_R1.fq
mv ./R2.dedup.fq ./step3.dedup/SRX2175964_R2.fq



fastuniq -i ./step3.dedup/SRX2175965_dedup_list.txt -o R1.dedup.fq -p R2.dedup.fq

mv ./R1.dedup.fq ./step3.dedup/SRX2175965_R1.fq
mv ./R2.dedup.fq ./step3.dedup/SRX2175965_R2.fq



