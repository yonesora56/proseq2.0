#!/usr/bin/env bash
set -euo pipefail

PROSEQ_HOME="/opt/proseq2.0"

usage() {
  cat <<EOF
Usage:
  proseq2.0 proseq2.0 [options]     Run proseq2.0.bsh pipeline
  proseq2.0 merge-bigwigs [options] Run mergeBigWigs.bsh

Examples:
  proseq2.0 proseq2.0 -SE -P -i /ref/index -c /ref/chromInfo -I sample -T /tmp -O /out
  proseq2.0 merge-bigwigs --chrom-info=/ref/chromInfo /out/merged.bw /out/a.bw /out/b.bw

Note: For proseq2.0, set working directory to the folder containing FASTQ files
      (docker run -w /data/input ...).
EOF
}

if [[ $# -lt 1 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]] || [[ "$1" == "help" ]]; then
  usage
  exit 0
fi

cmd="$1"
shift

case "${cmd}" in
  proseq2.0|proseq|mapper)
    exec bash "${PROSEQ_HOME}/proseq2.0.bsh" "$@"
    ;;
  merge-bigwigs|mergeBigWigs|merge)
    exec bash "${PROSEQ_HOME}/mergeBigWigs.bsh" "$@"
    ;;
  verify-versions)
    exec bash /opt/proseq2.0/docker/verify_versions.sh
    ;;
  -h|--help|help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown command: ${cmd}" >&2
    usage
    exit 1
    ;;
esac