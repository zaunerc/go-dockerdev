#!/bin/bash
set -e
. common.sh
docker build -t "$IMAGE_NAME" .

