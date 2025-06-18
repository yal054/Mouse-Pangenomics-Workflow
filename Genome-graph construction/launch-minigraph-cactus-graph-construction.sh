#!/bin/bash

java -Dconfig.file=cromwell.config -jar cromwell.jar run -t wdl -i mcgb-inputs.json mcgb.wdl
