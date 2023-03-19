#!/usr/bin/env bash

set -Eeufo pipefail

apk add --update-cache aws-cli

ACCOUNT_ID=253213882263
REGION=ap-southeast-2
REPO=rails-parallel-example

REGISTRY="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

echo "--- Logging into ECR :ecr:"
aws ecr get-login-password --region ap-southeast-2 |
  docker login --username AWS --password-stdin "$REGISTRY"


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
if [[ "${REBUILD_IMAGES:-false}" == "true" ]] || \
  ! aws ecr describe-images \
    --registry-id "$ACCOUNT_ID" \
    --repository-name "$REPO" \
    --image-ids imageTag="$BUILDKITE_COMMIT"
then
  docker buildx build \
    --progress plain \
    --builder "$builder_name" \
    --push \
    --platform linux/arm64 \
    --tag "$REGISTRY/$REPO:$BUILDKITE_COMMIT" \
    .
fi
