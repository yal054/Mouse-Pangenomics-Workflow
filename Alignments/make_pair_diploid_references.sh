#!/bin/bash

cat <(sed 's/^>/>PWK_PhJ./' PWK_PhJ.fna; echo) <(sed 's/^>/>CAST_EiJ./' CAST_EiJ.fna) > PWK_PhJxCAST_EiJ.fa
