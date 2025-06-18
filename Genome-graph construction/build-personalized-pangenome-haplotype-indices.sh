#!/bin/bash

vg gbwt -p --num-threads 30 \
 -r graph.ri \
 -Z graph.gbz && \
vg haplotypes -v 2 -t 30 \
 -H graph.hapl \
 graph.gbz

