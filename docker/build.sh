#!/usr/bin/env bash
# build.sh — build the Agent-LE XBestISA Docker image.
set -euo pipefail

cd "$(dirname "$0")/.."
docker build -t agent-le-xbestisa:1.0 -f docker/Dockerfile .

echo
echo "Built agent-le-xbestisa:1.0."
echo
echo "Run the grader with:"
echo "  docker run --rm -v \$PWD:/host -it agent-le-xbestisa:1.0 \\"
echo "    bash -c 'cd /work && bash grader/grade.sh && cp scorecard.json /host/'"
