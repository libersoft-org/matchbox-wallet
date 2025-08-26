#!/bin/bash
set -euo pipefail

./build-cross-x86-arm64.sh
./deploy.sh
