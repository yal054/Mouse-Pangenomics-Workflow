# Alignments and Metrics

Alignment quality and read-placement accuracy for short-read WGS from 40 CC RI
animals, compared across three references: GRCm38, the C57BL/6J mT2T assembly,
and the Founder Pangenome.

The alignments were produced by J. E. Garza and are inputs here.

## Alignment metrics

Eight conditions are compared: GRCm38 with BWA-MEM2, GRCm38 with giraffe before
surjection, GRCm38 with giraffe after surjection, the same three for mT2T, and
the Founder Pangenome with giraffe both before and after surjection.

- `Alignment_Benchmarking.md`: parse the `samtools stats` and `vg stats` outputs
  into a single R-ready table and validate it. 40 samples per reference, with
  the expected NA pattern for metrics that exist only in graph space or only in
  linear space
- `Compile_metrics.md`: the per-condition collection protocol for all eight
- `Alignment_Metrics_Comparison.Rmd`: mapping rate, properly paired rate,
  perfect and gapless reads, MAPQ 60 rate, MQ0 rate, error rate, insert size and
  singletons, plus mean alignment score and mean mapping quality for the
  pre-surjection graph conditions

MQ0 is reported only for the five linear-coordinate conditions, and mean mapping
quality only for the three pre-surjection ones, because those statistics are not
defined in the other space.

## Mapping accuracy (`mapping-accuracy/`)

Reads simulated from the 40 RI assemblies are aligned to each reference, lifted
back to their source coordinates, and scored as accurate if they land inside the
lifted interval. Reported per MAPQ bin.

- `Prepare_genome_alignments.md`: whole-genome alignments used to lift simulated
  reads back to the assembly they came from
- `Prepare_genome_alignments_T2T.md`: the same against the T2T reference
- `Calculate_mapping_accuracy.md`: the GRCm38 arm. Subsample, index the liftover
  PAFs, run the accuracy pipeline
- `Calculate_mapping_accuracy_mT2T_BWA.md`: the mT2T arm
- `Calculate_mapping_accuracy_pan.md`: the Founder Pangenome arm
- `Calculate_mapping_accuracy_{mm10,mT2T_BWA,Pan}.Rmd`: per-reference accuracy
  curves
- `Calculate_mapping_accuracy_Combined.Rmd`: all three references on one axis,
  per MAPQ bin

Accuracy was computed at several subsample fractions. The combined figure
filters to the 2% subsample.
