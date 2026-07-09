#!/usr/bin/env bash
# Build and push proseq2.0 image to Docker Hub.
#
# Prerequisites:
#   docker login
#
# Usage:
#   ./docker/publish.sh              # push VERSION from ./VERSION + :latest
#   ./docker/publish.sh 1.0.1        # push :1.0.1 and :latest
#   ./docker/publish.sh 1.0.1 --no-latest  # push :1.0.1 only

set -euo pipefail

IMAGE="${DOCKERHUB_IMAGE:-sorayone56/proseq2.0}"
BUILDER="${BUILDX_BUILDER:-multiarch-builder}"
PLATFORM="${DOCKER_PLATFORMS:-linux/amd64}"
PUSH_LATEST=1

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TAG="${1:-}"
if [[ -z "${TAG}" ]]; then
  TAG="$(tr -d '[:space:]' < VERSION)"
fi
if [[ -z "${TAG}" ]]; then
  echo "ERROR: version tag is required (set ./VERSION or pass as argument)" >&2
  exit 1
fi
if [[ "${2:-}" == "--no-latest" ]]; then
  PUSH_LATEST=0
fi

if ! docker buildx inspect "${BUILDER}" >/dev/null 2>&1; then
  echo "Creating buildx builder: ${BUILDER}"
  docker buildx create --name "${BUILDER}" --driver docker-container --use
else
  docker buildx use "${BUILDER}"
fi

TAGS=(-t "${IMAGE}:${TAG}")
if [[ "${PUSH_LATEST}" -eq 1 ]]; then
  TAGS+=(-t "${IMAGE}:latest")
fi

echo "Building and pushing ${IMAGE}:${TAG} for ${PLATFORM} ..."
docker buildx build \
  --platform "${PLATFORM}" \
  "${TAGS[@]}" \
  --push \
  --label "org.opencontainers.image.version=${TAG}" \
  .

echo ""
echo "Published:"
echo "  ${IMAGE}:${TAG}"
if [[ "${PUSH_LATEST}" -eq 1 ]]; then
  echo "  ${IMAGE}:latest"
fi
echo ""
echo "Pull on another machine (recommended: pin the version tag):"
echo "  docker pull ${IMAGE}:${TAG}"
echo "  docker run --rm --platform linux/amd64 ${IMAGE}:${TAG} verify-versions"
