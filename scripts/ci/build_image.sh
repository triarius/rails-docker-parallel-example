#!/usr/bin/env bash

set -Eeufo pipefail

apk add docker-cli-buildx aws-cli

REPO=253213882263.dkr.ecr.ap-southeast-2.amazonaws.com

echo "--- Logging into ECR :ecr:"
aws ecr get-login-password --region ap-southeast-2 |
  docker login --username AWS --password-stdin "$REPO"


builder_name=$(
  docker buildx create \
    --driver remote \
    --driver-opt cacert=/buildkit/certs/ca.pem,cert=/buildkit/certs/cert.pem,key=/buildkit/certs/key.pem \
    tcp://buildkitd.buildkite.svc:1234 \
    --use
)
# shellcheck disable=SC2064 # we want the current $builder_name to be trapped, not the runtime one
trap "docker buildx rm $builder_name" EXIT

echo "--- Building App Image :docker:"
docker buildx build \
  --progress plain \
  --builder "$builder_name" \
  --push \
  --platform linux/amd64,linux/arm64 \
  --tag "$REPO/rail-parallel-example:$BUILDKITE_COMMIT" \
  .
