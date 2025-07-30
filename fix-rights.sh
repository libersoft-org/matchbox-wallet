#!/bin/sh

find . -type f -executable \
-not -path "*/.git/*" \
-not -path "*/build/*" \
-not -name "*.sh" \
-exec echo "chmod -x {}" \;
