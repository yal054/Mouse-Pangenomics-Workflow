#!/bin/bash


fastuniq -i ./step3.dedup/SRX2175958_dedup_list.txt -o R1.dedup.fq -p R2.dedup.fq

mv ./R1.dedup.fq ./step3.dedup/SRX2175958_R1.fq
mv ./R2.dedup.fq ./step3.dedup/SRX2175958_R2.fq



fastuniq -i ./step3.dedup/SRX2175959_dedup_list.txt -o R1.dedup.fq -p R2.dedup.fq

mv ./R1.dedup.fq ./step3.dedup/SRX2175959_R1.fq
mv ./R2.dedup.fq ./step3.dedup/SRX2175959_R2.fq



fastuniq -i ./step3.dedup/SRX2175960_dedup_list.txt -o R1.dedup.fq -p R2.dedup.fq

mv ./R1.dedup.fq ./step3.dedup/SRX2175960_R1.fq
mv ./R2.dedup.fq ./step3.dedup/SRX2175960_R2.fq



fastuniq -i ./step3.dedup/SRX2175961_dedup_list.txt -o R1.dedup.fq -p R2.dedup.fq

mv ./R1.dedup.fq ./step3.dedup/SRX2175961_R1.fq
mv ./R2.dedup.fq ./step3.dedup/SRX2175961_R2.fq



