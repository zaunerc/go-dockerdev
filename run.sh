#!/bin/bash
set -e
. common.sh
CID=$(docker run -P "$IMAGE_NAME")

