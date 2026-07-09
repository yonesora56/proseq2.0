# =============================================================================
# proseq2.0 Docker image
# Docker image created date: 2026-07-09 (by Sora Yonezawa)
# Platform: linux/amd64
# Base:     mambaorg/micromamba:1.5-jammy
#
# Pinned bioinformatics tool versions (bioconda / conda-forge, linux-64):
# -----------------------------------------------------------------------------
# Tool                  Package (conda)              Version    Build
# -----------------------------------------------------------------------------
# cutadapt              cutadapt                     1.8.3      py27_0
# seqtk                 seqtk                        1.3        he4a0461_6
# prinseq-lite.pl       prinseq                      0.20.4     hdfd78af_5
# bwa                   bwa                          0.7.17     he4a0461_11
# samtools              samtools                     1.9        h10a08f8_12
# bedtools              bedtools                     2.28.0     hdf88d34_0
# bedops (sort-bed)     bedops                       2.4.41     h9948957_3
# bedGraphToBigWig      ucsc-bedgraphtobigwig        472        h9b8f530_1
# bigWigToBedGraph      ucsc-bigwigtobedgraph        469        h9b8f530_0
# perl (prinseq dep)    perl                         5.32.1     7_hd590300_perl5
# =============================================================================

FROM mambaorg/micromamba:1.5-jammy

# Explicit version pins (also used as documentation / CI checks)
ARG CUTADAPT_VERSION=1.8.3
ARG SEQTK_VERSION=1.3
ARG PRINSEQ_VERSION=0.20.4
ARG BWA_VERSION=0.7.17
ARG SAMTOOLS_VERSION=1.9
ARG BEDTOOLS_VERSION=2.28.0
ARG BEDOPS_VERSION=2.4.41
ARG UCSC_BEDGRAPHTOBIGWIG_VERSION=472
ARG UCSC_BIGWIGTOBEDGRAPH_VERSION=469
ARG PERL_VERSION=5.32.1
ARG IMAGE_VERSION=1.0.0

LABEL org.opencontainers.image.title="proseq2.0" \
      org.opencontainers.image.description="PRO-seq preprocessing pipeline (Danko Lab proseq2.0)" \
      org.opencontainers.image.licenses="BSD-2-Clause" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      proseq2.cutadapt="${CUTADAPT_VERSION}" \
      proseq2.seqtk="${SEQTK_VERSION}" \
      proseq2.prinseq="${PRINSEQ_VERSION}" \
      proseq2.bwa="${BWA_VERSION}" \
      proseq2.samtools="${SAMTOOLS_VERSION}" \
      proseq2.bedtools="${BEDTOOLS_VERSION}" \
      proseq2.bedops="${BEDOPS_VERSION}" \
      proseq2.ucsc-bedgraphtobigwig="${UCSC_BEDGRAPHTOBIGWIG_VERSION}" \
      proseq2.ucsc-bigwigtobedgraph="${UCSC_BIGWIGTOBEDGRAPH_VERSION}" \
      proseq2.perl="${PERL_VERSION}"

USER root
WORKDIR /opt/proseq2.0

# Install pinned conda environment
COPY environment.yml /tmp/environment.yml
RUN micromamba create -y -n proseq2 -f /tmp/environment.yml \
    && micromamba clean --all --yes \
    && rm /tmp/environment.yml

# Activate proseq2 env for subsequent layers and at runtime
ARG MAMBA_DOCKERFILE_ACTIVATE=1
ENV MAMBA_DEFAULT_ENV=proseq2
ENV PATH="/opt/conda/envs/proseq2/bin:/opt/proseq2.0:${PATH}"

# Copy pipeline scripts and docker helpers
COPY proseq2.0.bsh mergeBigWigs.bsh /opt/proseq2.0/
COPY docker/ /opt/proseq2.0/docker/
RUN chmod +x /opt/proseq2.0/docker/*.sh

# Verify all tools exist and match pinned versions
RUN bash /opt/proseq2.0/docker/verify_versions.sh \
    && bash /opt/proseq2.0/proseq2.0.bsh --help >/dev/null \
    && bash /opt/proseq2.0/mergeBigWigs.bsh --help >/dev/null

ENTRYPOINT ["/opt/proseq2.0/docker/entrypoint.sh"]
CMD ["--help"]
