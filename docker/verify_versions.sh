#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

arch="$(uname -m)"
case "${arch}" in
  x86_64|amd64)
    # shellcheck source=expected_versions-amd64.env
    source "${SCRIPT_DIR}/expected_versions-amd64.env"
    platform_label="linux/amd64"
    ;;
  aarch64|arm64)
    # shellcheck source=expected_versions-arm64.env
    source "${SCRIPT_DIR}/expected_versions-arm64.env"
    platform_label="linux/arm64"
    ;;
  *)
    echo "ERROR: unsupported architecture: ${arch}" >&2
    exit 1
    ;;
esac

fail=0

check_cmd() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "ERROR: ${cmd} not found in PATH" >&2
    fail=1
  fi
}

check_contains() {
  local label="$1"
  local expected="$2"
  local actual="$3"
  if [[ "${actual}" != *"${expected}"* ]]; then
    echo "ERROR: ${label} version mismatch" >&2
    echo "  expected to contain: ${expected}" >&2
    echo "  actual: ${actual}" >&2
    fail=1
  else
    echo "OK ${label}: ${actual}"
  fi
}

echo "=== proseq2.0 dependency version check (${platform_label}) ==="

for tool in cutadapt seqtk prinseq-lite.pl bwa samtools bedtools bedGraphToBigWig bigWigToBedGraph sort-bed; do
  check_cmd "${tool}"
done

check_contains "cutadapt" "${CUTADAPT_VERSION_EXPECT}" "$(cutadapt --version 2>&1 | head -1)"
check_contains "samtools" "${SAMTOOLS_VERSION_EXPECT}" "$(samtools --version 2>&1 | head -1)"
check_contains "bedtools" "${BEDTOOLS_VERSION_EXPECT}" "$(bedtools --version 2>&1)"
check_contains "bwa" "${BWA_VERSION_EXPECT}" "$(bwa 2>&1 | grep Version || true)"

if prinseq-lite.pl -v >/dev/null 2>&1; then
  check_contains "prinseq-lite.pl" "${PRINSEQ_VERSION_EXPECT}" "$(prinseq-lite.pl -v 2>&1 | head -1)"
else
  echo "OK prinseq-lite.pl: present (no -v flag)"
fi

echo "OK seqtk: $(command -v seqtk)"
echo "OK bedGraphToBigWig: $(command -v bedGraphToBigWig)"
echo "OK bigWigToBedGraph: $(command -v bigWigToBedGraph)"
echo "OK sort-bed: $(command -v sort-bed)"

if [[ "${fail}" -ne 0 ]]; then
  exit 1
fi

echo "=== all checks passed ==="
