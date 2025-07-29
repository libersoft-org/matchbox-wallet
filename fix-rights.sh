#!/bin/sh

find . -type f -executable \
-not -path "*/.git/*" \
-not -name "*.sh" \
-exec echo "chmod -x {}" \;
