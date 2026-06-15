- `pair-merge-sim-bwa-mm10-alns.sh`: merge pairs of mm10-aligned simulated reads to create in-silico diploid alignments
  - docker image: `ctomlins/samtools`
  - also indexed with `samtools index $BAM`
- `pair-merge-sim-giraffe-Founders-alns.sh`: merge pairs of Founder-aligned & surjected simulated reads to create in-silico diploid alignments
  - docker image: `ctomlins/samtools`
- `pairs.txt`: specifies the RI lines that were paired to make "diploid" alignments by both of the above scripts

- `create-real-truth-sets.sh`: create variant truth sets for real data from personalized diploid graphs containing inferred diploid assemblies for a given line
- `create-sim-truth-sets.sh`: create variant truth sets for simulated diploids from diploid graphs containing inferred haploid assemblies for both lines in the pair


- `batch-real-mpileup.sh`: calculate mpileups from real mm10 alignments and Founder surjected alignments
- `batch-sim-mpileup.sh`: calculate mpileups from simulated mm10 alignments and Founder surjected alignments

- `batch-isec.sh`: used to intersect all mpileup cohorts ([real,simulated] x [mm10,surjected] with their truth sets
