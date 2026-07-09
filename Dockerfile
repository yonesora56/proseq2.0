# =============================================================================
# proseq2.0 Docker image (multi-arch: linux/amd64 + linux/arm64)
# Base: mambaorg/micromamba:1.5-jammy
#
# linux/amd64 — README-aligned bioconda pins (environment-amd64.yml):
#   cutadapt 1.8.3, seqtk 1.3, prinseq 0.20.4, bwa 0.7.17, samtools 1.9,
#   bedtools 2.28.0, bedops 2.4.41, ucsc 472/469, perl 5.32.1
#
# linux/arm64 — best available bioconda pins (environment-arm64.yml):
#   cutadapt 5.2, seqtk 1.5, prinseq 0.20.4, bwa 0.7.19, samtools 1.23.1,
#   bedtools 2.31.1, bedops 2.4.42, ucsc 482/482, perl 5.32.1
# =============================================================================

FROM mambaorg/micromamba:1.5-jammy

ARG TARGETARCH
ARG IMAGE_VERSION=1.1.0

LABEL org.opencontainers.image.title="proseq2.0" \
      org.opencontainers.image.description="PRO-seq preprocessing pipeline (multi-arch)" \
      org.opencontainers.image.licenses="BSD-2-Clause" \
      org.opencontainers.image.version="${IMAGE_VERSION}"

USER root
WORKDIR /opt/proseq2.0

COPY environment-amd64.yml environment-arm64.yml /tmp/
RUN if [ "${TARGETARCH}" = "arm64" ]; then \
      ENV_FILE="/tmp/environment-arm64.yml"; \
    else \
      ENV_FILE="/tmp/environment-amd64.yml"; \
    fi && \
    echo "Installing proseq2 env for ${TARGETARCH} using ${ENV_FILE}" && \
    micromamba create -y -n proseq2 -f "${ENV_FILE}" && \
    micromamba clean --all --yes && \
    rm -f /tmp/environment-amd64.yml /tmp/environment-arm64.yml && \
    echo "${TARGETARCH}" > /opt/proseq2.0/.targetarch

ARG MAMBA_DOCKERFILE_ACTIVATE=1
ENV MAMBA_DEFAULT_ENV=proseq2
ENV PATH="/opt/conda/envs/proseq2/bin:/opt/proseq2.0:${PATH}"

COPY proseq2.0.bsh mergeBigWigs.bsh /opt/proseq2.0/
COPY docker/ /opt/proseq2.0/docker/
RUN chmod +x /opt/proseq2.0/docker/*.sh

RUN bash /opt/proseq2.0/docker/verify_versions.sh \
    && bash /opt/proseq2.0/proseq2.0.bsh --help >/dev/null \
    && bash /opt/proseq2.0/mergeBigWigs.bsh --help >/dev/null

ENTRYPOINT ["/opt/proseq2.0/docker/entrypoint.sh"]
CMD ["--help"]
