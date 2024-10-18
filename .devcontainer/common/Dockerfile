# syntax=docker/dockerfile:1.10.0
# refs:
# - https://docs.docker.com/build/buildkit/dockerfile-release-notes/
# - https://docs.docker.com/build/building/best-practices/
# - https://github.com/hadolint/hadolint
# - https://github.com/devcontainers/images/blob/main/src/universal/.devcontainer/Dockerfile
# - https://github.com/devcontainers/features/tree/main/src/common-utils
# - https://code.visualstudio.com/remote/advancedcontainers/overview

FROM ubuntu:noble-20240605

ARG DEVCONTAINER_UID
ARG DEVCONTAINER_GID
ARG DEVCONTAINER_USERNAME="devcontainer"
ARG DEVCONTAINER_HOME="/home/${DEVCONTAINER_USERNAME}"
ARG WORKSPACE="/home/${DEVCONTAINER_USERNAME}/workspace"
# possible values: [poc, slim, sensible, edge]
ARG DEVCONTAINER_VERSION="sensible"

# disable interactive dialogue
ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-Eeuo", "pipefail", "-c"]

RUN \
  # fix bad proxy
  echo 'Acquire::http::Pipeline-Depth 0;' > /etc/apt/apt.conf.d/99fixbadproxy

# user
RUN \
  [[ "${DEVCONTAINER_USERNAME}" = "root" ]] || id "${DEVCONTAINER_USERNAME}" &>/dev/null && exit 0; \
  EXISTING_USER=$(getent passwd "${DEVCONTAINER_UID}" | cut -d: -f1); \
  if [[ -n "${EXISTING_USER}" && "${EXISTING_USER}" != "${DEVCONTAINER_USERNAME}" ]]; then \
  usermod --uid $((DEVCONTAINER_UID + 1)) "${EXISTING_USER}"; \
  fi; \
  if getent group "${DEVCONTAINER_GID}" &>/dev/null; then \
  useradd --create-home --shell /bin/bash --uid "${DEVCONTAINER_UID}" --gid "${DEVCONTAINER_GID}" "${DEVCONTAINER_USERNAME}"; \
  else \
  groupadd --gid "${DEVCONTAINER_GID}" "${DEVCONTAINER_USERNAME}" && \
  useradd --create-home --shell /bin/bash --uid "${DEVCONTAINER_UID}" --gid "${DEVCONTAINER_GID}" "${DEVCONTAINER_USERNAME}"; \
  fi

# [poc, slim, sensible, edge]
# apt-get: pre-requisits/dev-dependencies
# hadolint ignore=DL3008,DL3009
RUN \
  --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
  --mount=target=/var/cache/apt,type=cache,sharing=locked \
  rm -f /etc/apt/apt.conf.d/docker-clean; \
  apt-get update -y \
  && apt-get upgrade -y \
  && apt-get install -y \
  --no-install-recommends \
  bash="5.2.*" \
  zsh="5.9*" \
  # gcc, g++, etc.
  build-essential="12.10*" \
  # update-ca-certificates
  ca-certificates="2024*" \
  # apt, apt-sortpkgs, apt-ftparchive, apt-extracttemplates, etc.
  apt-utils="2.7.*" \
  apt-transport-https="2.7.*" \
  # add-apt-repository, etc.
  software-properties-common="0.99.*" \
  # service, invoke-rc.d, update-rc.d, etc.
  init-system-helpers="1.66*" \
  # ssh, ssh-keygen, scp, sftp, etc.
  openssh-client="1:9.6*" \
  # cmake, cpack, ctest, etc.
  cmake="3.28.*" \
  # python(system)
  python3="3.12.3*" \
  python3-dev="3.12.3*" \
  # gpg
  gnupg1="1.4.*" \
  # gpg2
  gnupg2="2.4.*" \
  lzip="1.24.*" \
  # zip, zipnote, etc.
  zip="3.0*" \
  # unzip, zipgrep, etc.
  unzip="6.0*" \
  # bzip2, bunzip2, etc.
  bzip2="1.0.*" \
  # xz, unxz, etc.
  xz-utils="5.6.*" \
  # dirmngr, etc.
  dirmngr="2.4.*" \
  # tc, ip, etc.
  iproute2="6.1.*" \
  # ifconfig, netstat, route, iptunnel, etc.
  net-tools="2.10*" \
  # ps, kill, top, free, vmstat etc.
  procps="2:4.*" \
  lsof="4.95.*" \
  htop="3.3.*" \
  # pstree, killall, etc.
  psmisc="23.7*" \
  # lsb_release
  lsb-release="12.0*" \
  dialog="1.3*" \
  # locale-gen, update-locale, validlocale, etc.
  locales="2.39*" \
  ncdu="1.19*" \
  # strace, etc.
  strace="6.8*" \
  # less, lesspipe, etc.
  less="590*" \
  tree="2.1.*" \
  sudo="1.9.*" \
  original-awk="2023*" \
  gawk="1:5.2*" \
  mawk="1.3.*" \
  vim="2:9.1.*" \
  # rsync, rrsync, rsync-ssl, etc.
  rsync="3.2.*" \
  curl="8.5.*" \
  wget="1.21.*" \
  # c libs required by pyenv, etc.
  libkrb5-3="1.20.*" \
  libgssapi-krb5-2="1.20.*" \
  libicu[0-9][0-9] \
  liblttng-ust[0-9] \
  libbz2-dev="1.0.*" \
  libffi-dev="3.4.*" \
  liblzma-dev="5.6.*" \
  libncurses-dev="6.4*" \
  libreadline-dev="8.2*" \
  libsqlite3-dev="3.45.*" \
  zlib1g-dev="1:1.3*" \
  libssl-dev="3.0.*" \
  libssl3t64="3.0.*" \
  llvm="1:18.*" \
  tk-dev="8.6.*" \
  # protoc
  protobuf-compiler="3.21.*" \
  # man
  manpages="6.7*" \
  manpages-dev="6.7*" \
  man-db="2.12.*" \
  groff="1.23.*" \
  busybox="1:1.36.*" \
  # supervisord, etc.
  supervisor="4.2.*"

# [poc, slim, sensible, edge]
ARG GIT_VERSION
ARG PANDOC_VERSION
ARG MAKE_VERSION
WORKDIR /tempdir
# hadolint ignore=DL3009
RUN \
  # git
  # https://git-scm.com/
  # hadolint ignore=DL3009
  --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
  --mount=target=/var/cache/apt,type=cache,sharing=locked \
  rm -f /etc/apt/apt.conf.d/docker-clean; \
  add-apt-repository ppa:git-core/ppa \
  && apt-get update -y \
  && apt-get install -y \
  --no-install-recommends \
  git="1:${GIT_VERSION}*"; \
  # pandoc
  # https://github.com/jgm/pandoc
  TARGETARCH="$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME_WO_EXTENSION="pandoc-${PANDOC_VERSION}-1-${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.deb"; \
  wget --progress=dot:giga "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/${RELEASE_FILE_NAME}" \
  && dpkg -i "${RELEASE_FILE_NAME}"; \
  # make
  # https://www.gnu.org/software/make/
  RELEASE_FILE_NAME_WO_EXTENSION="make-${MAKE_VERSION}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.tar.gz"; \
  wget --progress=dot:giga --no-check-certificate "https://repo.jing.rocks/gnu/make/${RELEASE_FILE_NAME}" \
  && tar -zxvf "${RELEASE_FILE_NAME}" \
  && "./${RELEASE_FILE_NAME_WO_EXTENSION}/configure" --disable-dependency-tracking \
  && make \
  && make install
WORKDIR "${WORKSPACE}"

# [poc, slim, sensible, edge]
ARG PYENV_INSTALL_VERSION
ARG PYTHON_VERSION
ARG PIP_VERSION
ARG PYTHON_SETUP_TOOLS_VERSION
ARG WHEEL_VERSION
ARG ARGCOMPLETE_VERSION
ARG UV_VERSION
ENV PYENV_ROOT="${DEVCONTAINER_HOME}/.pyenv"
ENV PATH="${PYENV_ROOT}/shims:${PYENV_ROOT}/bin:${PATH}"
WORKDIR "${PYENV_ROOT}"
# hadolint ignore=SC1091
RUN \
  # pyenv
  # https://github.com/pyenv/pyenv
  git clone --depth 1 --single-branch --branch "v${PYENV_INSTALL_VERSION}" https://github.com/pyenv/pyenv.git "${PYENV_ROOT}" \
  && src/configure \
  && make -C src; \
  # python
  # https://www.python.org/
  pyenv install "${PYTHON_VERSION}" \
  && pyenv global "${PYTHON_VERSION}" \
  && pyenv rehash \
  && eval "$(pyenv init -)" \
  && pip install --no-cache-dir \
  # pip
  # https://github.com/pypa/pip
  pip=="${PIP_VERSION}" \
  # python-setup-tools
  # https://github.com/pypa/setuptools
  setuptools=="${PYTHON_SETUP_TOOLS_VERSION}" \
  # wheel
  # https://github.com/pypa/wheel
  wheel=="${WHEEL_VERSION}" \
  # argcomplete
  # https://github.com/kislyuk/argcomplete
  argcomplete=="${ARGCOMPLETE_VERSION}"; \
  # uv
  # https://github.com/astral-sh/uv
  BINARY_NAME="uv"; \
  REPOSITORY_NAME="astral-sh/uv"; \
  TAG_NAME="${UV_VERSION}"; \
  TARGETARCH="$(arch)"; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}-${TARGETARCH}-unknown-linux-gnu"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.tar.gz"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && tar -zxvf "${RELEASE_FILE_NAME}" \
  && install -v -m 0755 "${RELEASE_FILE_NAME_WO_EXTENSION}/uv" /usr/local/bin \
  && install -v -m 0755 "${RELEASE_FILE_NAME_WO_EXTENSION}/uvx" /usr/local/bin
WORKDIR "${WORKSPACE}"

# [poc, slim, sensible, edge]
ARG NODE_VERSION
ARG NPM_VERSION
ARG PNPM_VERSION
WORKDIR /tempdir
RUN \
  # node
  # https://nodejs.org/
  BINARY_NAME="node"; \
  TAG_NAME="v${NODE_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  if [[ "${TARGETARCH}" == "amd64" ]]; then TARGETARCH="x64"; fi; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}-${TAG_NAME}-linux-${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.tar.xz"; \
  wget --progress=dot:giga "https://nodejs.org/dist/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && tar -Jxvf "${RELEASE_FILE_NAME}" \
  && chmod -R 0755 "${RELEASE_FILE_NAME_WO_EXTENSION}" \
  && cp -vR "${RELEASE_FILE_NAME_WO_EXTENSION}/"{bin,lib,include,share} /usr/local/ \
  # npm
  # https://github.com/npm/cli
  && npm install --global \
  "npm@${NPM_VERSION}" \
  # pnpm
  # https://github.com/pnpm/pnpm
  "pnpm@${PNPM_VERSION}"
WORKDIR "${WORKSPACE}"

# [poc, slim, sensible, edge]
ARG GO_VERSION
ENV GOPATH="${DEVCONTAINER_HOME}/opt/go"
ENV PATH="${PATH}:/usr/local/go/bin:${GOPATH}/bin"
WORKDIR /tempdir
RUN \
  # golang
  # https://go.dev/
  mkdir -p "${GOPATH}"; \
  RELEASE_FILE_NAME_WO_EXTENSION="go${GO_VERSION}.linux-$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.tar.gz"; \
  wget --progress=dot:giga "https://go.dev/dl/${RELEASE_FILE_NAME}" \
  && tar -C /usr/local -zxvf "${RELEASE_FILE_NAME}"
WORKDIR "${WORKSPACE}"

# [poc, slim, sensible, edge]
ARG RUSTUP_VERSION
ARG RUST_VERSION
ENV RUSTUP_HOME="/usr/local/rustup"
ENV CARGO_HOME="/usr/local/cargo"
ENV PATH="/usr/local/cargo/bin:${PATH}"
WORKDIR /tempdir
RUN \
  # rust
  # https://www.rust-lang.org/
  wget --progress=dot:giga "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/$(uname -m)-unknown-linux-gnu/rustup-init" \
  && chmod +x rustup-init \
  && ./rustup-init -y --no-modify-path --profile minimal --default-toolchain "${RUST_VERSION}" \
  && chmod -R a+w "${RUSTUP_HOME}" "${CARGO_HOME}"
WORKDIR "${WORKSPACE}"

# [poc, slim, sensible, edge]
ARG JQ_VERSION
ARG YQ_VERSION
ARG FD_VERSION
ARG RIPGREP_VERSION
ARG SD_VERSION
ARG SLSA_VERIFIER_VERSION
ARG COSIGN_VERSION
ARG SOPS_VERSION
ARG AWS_CLI_VERSION
ARG GH_VERSION
WORKDIR /tempdir
RUN \
  # jq
  # https://github.com/jqlang/jq
  BINARY_NAME="jq"; \
  REPOSITORY_NAME="jqlang/jq"; \
  TAG_NAME="${BINARY_NAME}-${JQ_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}-linux-${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && mv -v "${RELEASE_FILE_NAME}" "${BINARY_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # yq
  # https://github.com/mikefarah/yq
  BINARY_NAME="yq"; \
  REPOSITORY_NAME="mikefarah/yq"; \
  TAG_NAME="v${YQ_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}_linux_${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.tar.gz"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && tar -zxvf "${RELEASE_FILE_NAME}" \
  && mv -v "${RELEASE_FILE_NAME_WO_EXTENSION}" "${BINARY_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # fd
  # https://github.com/sharkdp/fd
  BINARY_NAME="fd"; \
  REPOSITORY_NAME="sharkdp/fd"; \
  TAG_NAME="v${FD_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}-musl_${FD_VERSION}_${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.deb"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && dpkg -i "${RELEASE_FILE_NAME}"; \
  # ripgrep(rg)
  # https://github.com/BurntSushi/ripgrep
  BINARY_NAME="rg"; \
  REPOSITORY_NAME="BurntSushi/ripgrep"; \
  TAG_NAME="${RIPGREP_VERSION}"; \
  TARGETARCH="$(arch)"; \
  if [[ "${TARGETARCH}" == "aarch64" ]]; then \
  RELEASE_FILE_NAME_WO_EXTENSION="ripgrep-${RIPGREP_VERSION}-${TARGETARCH}-unknown-linux-gnu"; \
  elif [[ "${TARGETARCH}" == "x86_64" ]]; then \
  RELEASE_FILE_NAME_WO_EXTENSION="ripgrep-${RIPGREP_VERSION}-${TARGETARCH}-unknown-linux-musl"; \
  fi; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.tar.gz"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && tar -zxvf "${RELEASE_FILE_NAME}" \
  && mv -v "${RELEASE_FILE_NAME_WO_EXTENSION}/${BINARY_NAME}" "${BINARY_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # sd
  # https://github.com/chmln/sd
  cargo install \
  "sd@${SD_VERSION}"; \
  # slsa-verifier
  # https://github.com/slsa-framework
  BINARY_NAME="slsa-verifier"; \
  SLSA_VERIFIER_STABLE_VERSION="2.5.1"; \
  STABLE_BINARY_NAME="slsa-verifier@stable"; \
  REPOSITORY_NAME="slsa-framework/slsa-verifier"; \
  TAG_NAME="v${SLSA_VERIFIER_VERSION}"; \
  STABLE_TAG_NAME="v${SLSA_VERIFIER_STABLE_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME="${BINARY_NAME}-linux-${TARGETARCH}"; \
  wget --progress=dot:giga "https://raw.githubusercontent.com/${REPOSITORY_NAME}/main/SHA256SUM.md" \
  && wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${STABLE_TAG_NAME}/${RELEASE_FILE_NAME}" \
  && wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${STABLE_TAG_NAME}/${RELEASE_FILE_NAME}.intoto.jsonl" \
  && cat SHA256SUM.md | grep "v${SLSA_VERIFIER_STABLE_VERSION}" -A7 | sha256sum -c --strict --ignore-missing \
  && cp -v "${RELEASE_FILE_NAME}" "${STABLE_BINARY_NAME}" \
  && chmod +x "${STABLE_BINARY_NAME}" \
  && "./${STABLE_BINARY_NAME}" verify-artifact "${RELEASE_FILE_NAME}" \
  --provenance-path "${RELEASE_FILE_NAME}.intoto.jsonl" \
  --source-uri "github.com/${REPOSITORY_NAME}" \
  --source-tag "${STABLE_TAG_NAME}" \
  && rm -f "${RELEASE_FILE_NAME}" \
  && "${RELEASE_FILE_NAME}.intoto.jsonl" \
  && wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}.intoto.jsonl" \
  && "./${STABLE_BINARY_NAME}" verify-artifact "${RELEASE_FILE_NAME}" \
  --provenance-path "${RELEASE_FILE_NAME}.intoto.jsonl" \
  --source-uri "github.com/${REPOSITORY_NAME}" \
  --source-tag "${TAG_NAME}" \
  && mv -v "${RELEASE_FILE_NAME}" "${BINARY_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # cosign
  # https://github.com/sigstore/cosign
  BINARY_NAME="cosign"; \
  COSIGN_STABLE_VERSION="2.4.0"; \
  STABLE_BINARY_NAME="cosign@stable"; \
  REPOSITORY_NAME="sigstore/cosign"; \
  TAG_NAME="v${COSIGN_VERSION}"; \
  STABLE_TAG_NAME="v${COSIGN_STABLE_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME="${BINARY_NAME}-linux-${TARGETARCH}"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${STABLE_TAG_NAME}/${RELEASE_FILE_NAME}" \
  && wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${STABLE_TAG_NAME}/${RELEASE_FILE_NAME}-keyless.pem" \
  && wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${STABLE_TAG_NAME}/${RELEASE_FILE_NAME}-keyless.sig" \
  && wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${STABLE_TAG_NAME}/cosign_checksums.txt" \
  && sha256sum -c --strict cosign_checksums.txt --ignore-missing \
  && base64 -d "${RELEASE_FILE_NAME}-keyless.pem" > cosign-release.pem.decoded \
  && base64 -d "${RELEASE_FILE_NAME}-keyless.sig" > cosign-release.sig.decoded \
  && cp -v "${RELEASE_FILE_NAME}" "${STABLE_BINARY_NAME}" \
  && chmod +x "${STABLE_BINARY_NAME}" \
  && "./${STABLE_BINARY_NAME}" verify-blob "${RELEASE_FILE_NAME}" \
  --certificate cosign-release.pem.decoded \
  --signature cosign-release.sig.decoded \
  --certificate-identity keyless@projectsigstore.iam.gserviceaccount.com \
  --certificate-oidc-issuer https://accounts.google.com \
  && rm -f "${RELEASE_FILE_NAME}" \
  "${RELEASE_FILE_NAME}-keyless.pem" \
  cosign-release.pem.decoded \
  "${RELEASE_FILE_NAME}-keyless.sig" \
  cosign-release.sig.decoded \
  cosign_checksums.txt \
  && wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}-keyless.pem" \
  && wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}-keyless.sig" \
  && wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/cosign_checksums.txt" \
  && wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/cosign_checksums.txt-keyless.pem" \
  && wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/cosign_checksums.txt-keyless.sig" \
  && sha256sum -c --strict cosign_checksums.txt --ignore-missing \
  && base64 -d "${RELEASE_FILE_NAME}-keyless.pem" > cosign-release.pem.decoded \
  && base64 -d "${RELEASE_FILE_NAME}-keyless.sig" > cosign-release.sig.decoded \
  && "./${STABLE_BINARY_NAME}" verify-blob "${RELEASE_FILE_NAME}" \
  --certificate cosign-release.pem.decoded \
  --signature cosign-release.sig.decoded \
  --certificate-identity keyless@projectsigstore.iam.gserviceaccount.com \
  --certificate-oidc-issuer https://accounts.google.com \
  && base64 -d "cosign_checksums.txt-keyless.pem" > cosign-release.pem.decoded \
  && base64 -d "cosign_checksums.txt-keyless.sig" > cosign-release.sig.decoded \
  && "./${STABLE_BINARY_NAME}" verify-blob cosign_checksums.txt \
  --certificate cosign-release.pem.decoded \
  --signature cosign-release.sig.decoded \
  --certificate-identity keyless@projectsigstore.iam.gserviceaccount.com \
  --certificate-oidc-issuer https://accounts.google.com \
  && mv -v "${RELEASE_FILE_NAME}" "${BINARY_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # sops
  # https://github.com/getsops/sops
  BINARY_NAME="sops"; \
  REPOSITORY_NAME="getsops/sops"; \
  TAG_NAME="v${SOPS_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME="${BINARY_NAME}-${TAG_NAME}.linux.${TARGETARCH}"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${BINARY_NAME}-${TAG_NAME}.checksums.txt" \
  && wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${BINARY_NAME}-${TAG_NAME}.checksums.pem" \
  && wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${BINARY_NAME}-${TAG_NAME}.checksums.sig" \
  && wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${BINARY_NAME}-${TAG_NAME}.intoto.jsonl" \
  && cosign verify-blob "${BINARY_NAME}-${TAG_NAME}.checksums.txt" \
  --certificate "${BINARY_NAME}-${TAG_NAME}.checksums.pem" \
  --signature "${BINARY_NAME}-${TAG_NAME}.checksums.sig" \
  --certificate-identity-regexp https://github.com/getsops \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  && sha256sum -c --strict "${BINARY_NAME}-${TAG_NAME}.checksums.txt" --ignore-missing \
  && slsa-verifier verify-artifact "${RELEASE_FILE_NAME}" \
  --provenance-path "${BINARY_NAME}-${TAG_NAME}.intoto.jsonl" \
  --source-uri "github.com/${REPOSITORY_NAME}" \
  --source-tag "${TAG_NAME}" \
  && mv -v "${RELEASE_FILE_NAME}" "${BINARY_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # aws cli
  # https://github.com/aws/aws-cli/tree/v2
  RELEASE_FILE_NAME_WO_EXTENSION="awscli-exe-linux-$(uname -m)-${AWS_CLI_VERSION}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.zip"; \
  wget --progress=dot:giga "https://awscli.amazonaws.com/${RELEASE_FILE_NAME}" \
  && unzip "${RELEASE_FILE_NAME}" \
  && ./aws/install; \
  # gh
  # https://github.com/cli/cli
  BINARY_NAME="gh"; \
  REPOSITORY_NAME="cli/cli"; \
  TAG_NAME="v${GH_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME_WO_EXTENSION="gh_${GH_VERSION}_linux_${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.tar.gz"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && tar -zxvf "${RELEASE_FILE_NAME}" \
  && mv -v "${RELEASE_FILE_NAME_WO_EXTENSION}/bin/${BINARY_NAME}" "${BINARY_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin
WORKDIR "${WORKSPACE}"

# [poc, slim, sensible, edge]
ARG TERRAFORM_VERSION
ARG TERRAGRUNT_VERSION
ARG ECSPRESSO_VERSION
ARG GO_JSONNET_VERSION
WORKDIR /tempdir
RUN \
  # terraform
  # https://github.com/hashicorp/terraform
  BINARY_NAME="terraform"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}_${TERRAFORM_VERSION}_linux_${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.zip"; \
  wget --progress=dot:giga "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${RELEASE_FILE_NAME}" \
  && unzip "${RELEASE_FILE_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # terragrunt
  # https://github.com/gruntwork-io/terragrunt
  BINARY_NAME="terragrunt"; \
  REPOSITORY_NAME="gruntwork-io/terragrunt"; \
  TAG_NAME="v${TERRAGRUNT_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME="${BINARY_NAME}_linux_${TARGETARCH}"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && mv -v "${RELEASE_FILE_NAME}" "${BINARY_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # ecspresso
  # https://github.com/kayac/ecspresso
  BINARY_NAME="ecspresso"; \
  REPOSITORY_NAME="kayac/ecspresso"; \
  TAG_NAME="v${ECSPRESSO_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}_${ECSPRESSO_VERSION}_linux_${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.tar.gz"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && tar -zxvf "${RELEASE_FILE_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # go-jsonnet(jsonnet, jsonnet-lint, jsonnetfmt)
  # https://github.com/google/go-jsonnet
  go install "github.com/google/go-jsonnet/cmd/jsonnet@v${GO_JSONNET_VERSION}" \
  && go install "github.com/google/go-jsonnet/cmd/jsonnet-lint@v${GO_JSONNET_VERSION}" \
  && go install "github.com/google/go-jsonnet/cmd/jsonnetfmt@v${GO_JSONNET_VERSION}"
WORKDIR "${WORKSPACE}"

# [sensible, edge]
ARG TFLINT_VERSION
ARG HCLFMT_VERSION
ARG TERRAFORM_DOCS_VERSION
ARG TRIVY_VERSION
ARG SHFMT_VERSION
ARG SHELLCHECK_VERSION
ARG BATS_VERSION
ARG HADOLINT_VERSION
WORKDIR /tempdir
# hadolint ignore=DL3003
RUN \
  [[ "${DEVCONTAINER_VERSION}" != "sensible" && "${DEVCONTAINER_VERSION}" != "edge" ]] && exit 0; \
  eval "$(pyenv init -)"; \
  # tflint
  # https://github.com/terraform-linters/tflint
  BINARY_NAME="tflint"; \
  REPOSITORY_NAME="terraform-linters/tflint"; \
  TAG_NAME="v${TFLINT_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}_linux_${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.zip"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && unzip "${RELEASE_FILE_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # hclfmt
  # https://github.com/hashicorp/hcl
  # https://github.com/hashicorp/hcl/tree/main/cmd/hclfmt
  go install "github.com/hashicorp/hcl/v2/cmd/hclfmt@v${HCLFMT_VERSION}"; \
  # terraform-docs
  # https://github.com/terraform-docs/terraform-docs
  BINARY_NAME="terraform-docs"; \
  REPOSITORY_NAME="terraform-docs/terraform-docs"; \
  TAG_NAME="v${TERRAFORM_DOCS_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}-${TAG_NAME}-linux-${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.tar.gz"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && tar -zxvf "${RELEASE_FILE_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # trivy
  # https://github.com/aquasecurity/trivy
  BINARY_NAME="trivy"; \
  REPOSITORY_NAME="aquasecurity/trivy"; \
  TAG_NAME="v${TRIVY_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  if [[ "${TARGETARCH}" == "amd64" ]]; then TARGETARCH="64bit"; elif [[ "${TARGETARCH}" == "arm64" ]]; then TARGETARCH="ARM64"; fi; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}_${TRIVY_VERSION}_Linux-${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.tar.gz"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && tar -zxvf "${RELEASE_FILE_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # shfmt
  # https://github.com/mvdan/sh
  BINARY_NAME="shfmt"; \
  REPOSITORY_NAME="mvdan/sh"; \
  TAG_NAME="v${SHFMT_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}_${TAG_NAME}_linux_${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && mv -v "${RELEASE_FILE_NAME}" "${BINARY_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # shellcheck
  # https://github.com/koalaman/shellcheck
  BINARY_NAME="shellcheck"; \
  REPOSITORY_NAME="koalaman/shellcheck"; \
  TAG_NAME="v${SHELLCHECK_VERSION}"; \
  TARGETARCH="$(arch)"; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}-${TAG_NAME}.linux.${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.tar.xz"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && tar -Jxvf "${RELEASE_FILE_NAME}" \
  && mv -v "shellcheck-v${SHELLCHECK_VERSION}/shellcheck" "${BINARY_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # bats
  # https://github.com/bats-core/bats-core
  git clone --depth 1 --single-branch --branch "v${BATS_VERSION}" https://github.com/bats-core/bats-core.git \
  && ./bats-core/install.sh /usr/local; \
  # hadolint
  # https://github.com/hadolint/hadolint
  BINARY_NAME="hadolint"; \
  REPOSITORY_NAME="hadolint/hadolint"; \
  TAG_NAME="v${HADOLINT_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  if [[ "${TARGETARCH}" == "amd64" ]]; then TARGETARCH="x86_64"; fi; \
  RELEASE_FILE_NAME_WO_EXTENSION="hadolint-Linux-${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && mv -v "${RELEASE_FILE_NAME}" "${BINARY_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin
WORKDIR "${WORKSPACE}"

# [sensible, edge]
ARG CHECKMAKE_VERSION
ARG TAPLO_VERSION
ARG EDITORCONFIG_CHECKER_VERSION
ARG DOTENV_LINTER_VERSION
ARG ESLINT_VERSION
ARG ESLINT_PLUGIN_YML_VERSION
ARG BIOME_VERSION
ARG YAMLFMT_VERSION
ARG YAMLLINT_VERSION
ARG ACTIONLINT_VERSION
ARG ACTION_VALIDATOR_VERSION
ARG CHECK_JSONSCHEMA_VERSION
ARG MARKDOWNLINT_CLI2_VERSION
ARG PARLIAMENT_VERSION
ARG PROSELINT_VERSION
ARG CSPELL_VERSION
ARG TEXTLINT_VERSION
ARG ALEX_VERSION
ARG WRITE_GOOD_VERSION
ARG PRE_COMMIT_VERSION
ARG COMMITLINT_VERSION
ARG COMMITLINT_CONFIG_CONVENTIONAL_VERSION
ARG COMMITIZEN_VERSION
WORKDIR /tempdir
# hadolint ignore=DL3003
RUN \
  [[ "${DEVCONTAINER_VERSION}" != "sensible" && "${DEVCONTAINER_VERSION}" != "edge" ]] && exit 0; \
  eval "$(pyenv init -)"; \
  # checkmake
  # https://github.com/mrtazz/checkmake
  git clone --depth 1 --single-branch --branch "${CHECKMAKE_VERSION}" https://github.com/mrtazz/checkmake \
  && cd /tempdir/checkmake || exit; \
  BINARY_NAME="checkmake"; \
  export BUILDER_NAME="docker"; \
  export BUILDER_EMAIL="docker@builder"; \
  make \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  cd /tempdir || exit; \
  # taplo
  # https://github.com/tamasfe/taplo
  BINARY_NAME="taplo"; \
  REPOSITORY_NAME="tamasfe/taplo"; \
  TAG_NAME="${TAPLO_VERSION}"; \
  TARGETARCH="$(arch)"; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}-full-linux-${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.gz"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && gunzip -c "${RELEASE_FILE_NAME}" > "${BINARY_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # editorconfig-checker
  # https://github.com/editorconfig-checker/editorconfig-checker
  BINARY_NAME="ec"; \
  REPOSITORY_NAME="editorconfig-checker/editorconfig-checker"; \
  TAG_NAME="v${EDITORCONFIG_CHECKER_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}-linux-${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.tar.gz"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && tar -zxvf "${RELEASE_FILE_NAME}" \
  && mv -v "./bin/${RELEASE_FILE_NAME_WO_EXTENSION}" "${BINARY_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # dotenv-linter
  # https://github.com/dotenv-linter/dotenv-linter
  cargo install \
  "dotenv-linter@${DOTENV_LINTER_VERSION}"; \
  # eslint
  # https://github.com/eslint/eslint
  # eslint-plugin-yml
  # https://github.com/ota-meshi/eslint-plugin-yml
  npm install --global \
  "eslint@${ESLINT_VERSION}" \
  "eslint-plugin-yml@${ESLINT_PLUGIN_YML_VERSION}" \
  # biome
  # https://github.com/biomejs/biome
  "@biomejs/biome@${BIOME_VERSION}"; \
  # yamlfmt
  # https://github.com/google/yamlfmt
  BINARY_NAME="yamlfmt"; \
  REPOSITORY_NAME="google/yamlfmt"; \
  TAG_NAME="v${YAMLFMT_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  if [[ "${TARGETARCH}" == "amd64" ]]; then TARGETARCH="x86_64"; fi; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}_${YAMLFMT_VERSION}_Linux_${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.tar.gz"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && tar -zxvf "${RELEASE_FILE_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # yamllint
  # https://github.com/adrienverge/yamllint
  pip install --no-cache-dir \
  yamllint=="${YAMLLINT_VERSION}"; \
  # actionlint
  # https://github.com/rhysd/actionlint
  BINARY_NAME="actionlint"; \
  REPOSITORY_NAME="rhysd/actionlint"; \
  TAG_NAME="v${ACTIONLINT_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}_${ACTIONLINT_VERSION}_linux_${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.tar.gz"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && tar -zxvf "${RELEASE_FILE_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # action-validator
  # https://github.com/mpalmer/action-validator
  BINARY_NAME="action-validator"; \
  REPOSITORY_NAME="mpalmer/action-validator"; \
  TAG_NAME="v${ACTION_VALIDATOR_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}_linux_${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && mv -v "${RELEASE_FILE_NAME}" "${BINARY_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # check-jsonschema
  # https://github.com/python-jsonschema/check-jsonschema
  pip install --no-cache-dir \
  check-jsonschema=="${CHECK_JSONSCHEMA_VERSION}"; \
  # markdownlint-cli2
  # https://github.com/DavidAnson/markdownlint-cli2
  npm install --global \
  "markdownlint-cli2@${MARKDOWNLINT_CLI2_VERSION}"; \
  # parliament
  # https://github.com/duo-labs/parliament
  pip install --no-cache-dir \
  parliament=="${PARLIAMENT_VERSION}" \
  # proselint
  # https://github.com/amperser/proselint
  # hadolint ignore=SC1091
  proselint=="${PROSELINT_VERSION}"; \
  # cspell
  # https://github.com/streetsidesoftware/cspell
  npm install --global \
  "cspell@${CSPELL_VERSION}" \
  # textlint
  # https://github.com/textlint/textlint
  "textlint@${TEXTLINT_VERSION}" \
  # alex
  # https://github.com/get-alex/alex
  "alex@${ALEX_VERSION}" \
  # write-good
  # https://github.com/btford/write-good
  "write-good@${WRITE_GOOD_VERSION}"; \
  # pre-commit
  # https://github.com/pre-commit/pre-commit
  pip install --no-cache-dir \
  pre-commit=="${PRE_COMMIT_VERSION}"; \
  # commitlint
  # commitlint-config-conventional
  # https://github.com/conventional-changelog/commitlint
  npm install --global \
  "@commitlint/cli@${COMMITLINT_VERSION}" \
  "@commitlint/config-conventional@${COMMITLINT_CONFIG_CONVENTIONAL_VERSION}" \
  # commitizen
  # https://github.com/commitizen/cz-cli
  "commitizen@${COMMITIZEN_VERSION}"
WORKDIR "${WORKSPACE}"

# [sensible, edge]
ARG PYTEST_VERSION
ARG TESTINFRA_VERSION
ARG RUFF_VERSION
ARG PYLINT_VERSION
ARG MYPY_VERSION
ARG PYRIGHT_VERSION
WORKDIR /tempdir
# hadolint ignore=DL3003
RUN \
  [[ "${DEVCONTAINER_VERSION}" != "sensible" && "${DEVCONTAINER_VERSION}" != "edge" ]] && exit 0; \
  eval "$(pyenv init -)"; \
  # pytest
  # https://github.com/pytest-dev/pytest
  # hadolint ignore=SC1091
  pip install --no-cache-dir \
  pytest=="${PYTEST_VERSION}" \
  # ruff
  # https://github.com/astral-sh/ruff
  ruff=="${RUFF_VERSION}" \
  # pylint
  # https://github.com/pylint-dev/pylint
  pylint=="${PYLINT_VERSION}" \
  # mypy
  # https://github.com/python/mypy
  mypy=="${MYPY_VERSION}" \
  # pyright
  # https://github.com/RobertCraigie/pyright-python
  pyright=="${PYRIGHT_VERSION}"
WORKDIR "${WORKSPACE}"

# [sensible, edge]
ARG STARSHIP_VERSION
ARG ZOXIDE_VERSION
ARG MCFLY_VERSION
WORKDIR /tempdir
# hadolint ignore=DL3003
RUN \
  [[ "${DEVCONTAINER_VERSION}" != "sensible" && "${DEVCONTAINER_VERSION}" != "edge" ]] && exit 0; \
  # starship
  # https://github.com/starship/starship
  cargo install \
  "starship@${STARSHIP_VERSION}"; \
  # zoxide
  # https://github.com/ajeetdsouza/zoxide
  BINARY_NAME="zoxide"; \
  REPOSITORY_NAME="ajeetdsouza/zoxide"; \
  TAG_NAME="v${ZOXIDE_VERSION}"; \
  TARGETARCH="$(arch)"; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}-${ZOXIDE_VERSION}-${TARGETARCH}-unknown-linux-musl"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.tar.gz"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && tar -zxvf "${RELEASE_FILE_NAME}" \
  && cp -vR ./man /usr/local/share \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # mcfly
  # https://github.com/cantino/mcfly
  BINARY_NAME="mcfly"; \
  REPOSITORY_NAME="cantino/mcfly"; \
  TAG_NAME="v${MCFLY_VERSION}"; \
  TARGETARCH="$(arch)"; \
  if [ "$TARGETARCH" = "x86_64" ]; then \
  LIBC="musl"; \
  else \
  LIBC="gnu"; \
  fi; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}-${TAG_NAME}-${TARGETARCH}-unknown-linux-${LIBC}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.tar.gz"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && tar -zxvf "${RELEASE_FILE_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin
WORKDIR "${WORKSPACE}"

# [edge]
ARG TENV_VERSION
ARG TFUPDATE_VERSION
ARG TF_SUMMARIZE_VERSION
ARG INFRACOST_VERSION
ARG INFRAMAP_VERSION
ARG ANSIBLE_VERSION
ARG ANSIBLE_LINT_VERSION
ARG CHECKOV_VERSION
ARG TERRASCAN_VERSION
WORKDIR /tempdir
# hadolint ignore=SC1091,DL3003,DL4001
RUN \
  [[ "${DEVCONTAINER_VERSION}" != "edge" ]] && exit 0; \
  eval "$(pyenv init -)"; \
  # tenv
  # https://github.com/tofuutils/tenv
  TARGETARCH="$(dpkg --print-architecture)"; \
  REPOSITORY_NAME="tofuutils/tenv"; \
  TAG_NAME="v${TENV_VERSION}"; \
  RELEASE_FILE_NAME_WO_EXTENSION="tenv_v${TENV_VERSION}_${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.deb"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && dpkg -i "${RELEASE_FILE_NAME}"; \
  # tfupdate
  # https://github.com/minamijoyo/tfupdate
  BINARY_NAME="tfupdate"; \
  REPOSITORY_NAME="minamijoyo/tfupdate"; \
  TAG_NAME="${TFUPDATE_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}_${TFUPDATE_VERSION}_linux_${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.tar.gz"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/v${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && tar -zxvf "${RELEASE_FILE_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # tf-summarize
  # https://github.com/dineshba/tf-summarize
  BINARY_NAME="tf-summarize"; \
  REPOSITORY_NAME="dineshba/tf-summarize"; \
  TAG_NAME="${TF_SUMMARIZE_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}_linux_${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.tar.gz"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/v${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && tar -zxvf "${RELEASE_FILE_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # infracost
  # https://github.com/infracost/infracost
  BINARY_NAME="infracost"; \
  REPOSITORY_NAME="infracost/infracost"; \
  TAG_NAME="v${INFRACOST_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}-linux-${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.tar.gz"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && tar -zxvf "${RELEASE_FILE_NAME}" \
  && mv -v "${RELEASE_FILE_NAME_WO_EXTENSION}" "${BINARY_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # inframap
  # https://github.com/cycloidio/inframap
  git clone --depth 1 --single-branch --branch "v${INFRAMAP_VERSION}" https://github.com/cycloidio/inframap.git \
  && cd /tempdir/inframap || exit; \
  go mod download \
  && make build \
  && install -v -m 0755 inframap /usr/local/bin \
  && cd /tempdir || exit; \
  # ansible
  # https://github.com/ansible/ansible
  pip install --no-cache-dir \
  ansible=="${ANSIBLE_VERSION}" \
  # ansible-lint
  # https://github.com/ansible/ansible-lint
  ansible-lint=="${ANSIBLE_LINT_VERSION}" \
  # checkov
  # https://github.com/bridgecrewio/checkov
  checkov=="${CHECKOV_VERSION}"; \
  # terrascan
  # https://github.com/tenable/terrascan
  BINARY_NAME="terrascan"; \
  REPOSITORY_NAME="tenable/terrascan"; \
  TAG_NAME="v${TERRASCAN_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  if [[ "${TARGETARCH}" == "amd64" ]]; then TARGETARCH="x86_64"; fi; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}_${TERRASCAN_VERSION}_Linux_${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.tar.gz"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && tar -zxvf "${RELEASE_FILE_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin
WORKDIR "${WORKSPACE}"

# [edge]
ARG FNM_VERSION
ARG SQLFLUFF_VERSION
ARG ACT_VERSION
ARG REVIEWDOG_VERSION
ARG GOSU_VERSION
ARG MOBY_VERSION
ARG DOCKER_CLI_VERSION
ARG DOCKER_BUILDX_VERSION
ARG DOCKER_COMPOSE_VERSION
ARG CONTAINERD_VERSION
ARG RELEASE_PLEASE_VERSION
ARG SEMANTIC_RELEASE_VERSION
ARG DIRENV_VERSION
ARG DEVCONTAINERS_CLI_VERSION
WORKDIR /tempdir
# hadolint ignore=SC1091,DL3003,DL4001
RUN \
  --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
  --mount=target=/var/cache/apt,type=cache,sharing=locked \
  rm -f /etc/apt/apt.conf.d/docker-clean; \
  [[ "${DEVCONTAINER_VERSION}" != "edge" ]] && exit 0; \
  eval "$(pyenv init -)"; \
  # fnm
  # https://github.com/Schniz/fnm
  BINARY_NAME="fnm"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  REPOSITORY_NAME="Schniz/fnm"; \
  TAG_NAME="v${FNM_VERSION}"; \
  if [[ "${TARGETARCH}" == "amd64" ]]; then TARGETARCH="linux"; fi; \
  RELEASE_FILE_NAME_WO_EXTENSION="fnm-${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.zip"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && unzip "${RELEASE_FILE_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # sqlfluff
  # https://github.com/sqlfluff/sqlfluff
  pip install --no-cache-dir \
  sqlfluff=="${SQLFLUFF_VERSION}"; \
  # act
  # https://github.com/nektos/act
  BINARY_NAME="act"; \
  REPOSITORY_NAME="nektos/act"; \
  TAG_NAME="v${ACT_VERSION}"; \
  TARGETARCH="$(dpkg --print-architecture)"; \
  if [[ "${TARGETARCH}" == "amd64" ]]; then TARGETARCH="x86_64"; fi; \
  RELEASE_FILE_NAME_WO_EXTENSION="${BINARY_NAME}_Linux_${TARGETARCH}"; \
  RELEASE_FILE_NAME="${RELEASE_FILE_NAME_WO_EXTENSION}.tar.gz"; \
  wget --progress=dot:giga "https://github.com/${REPOSITORY_NAME}/releases/download/${TAG_NAME}/${RELEASE_FILE_NAME}" \
  && tar -zxvf "${RELEASE_FILE_NAME}" \
  && install -v -m 0755 "${BINARY_NAME}" /usr/local/bin; \
  # reviewdog
  # https://github.com/reviewdog/reviewdog
  curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "$(go env GOPATH)/bin" "v${REVIEWDOG_VERSION}"; \
  # gosu
  # https://github.com/tianon/gosu
  TARGETARCH="$(dpkg --print-architecture)"; \
  RELEASE_FILE_NAME_WO_EXTENSION="gosu-${TARGETARCH}"; \
  wget --progress=dot:giga  -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/${RELEASE_FILE_NAME_WO_EXTENSION}" \
  && wget --progress=dot:giga  -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/${RELEASE_FILE_NAME_WO_EXTENSION}.asc"; \
  # verify the signature
  GNUPGHOME="$(mktemp -d)"; \
  export GNUPGHOME; \
  gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
  && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
  && gpgconf --kill all \
  && rm -rf "${GNUPGHOME}" /usr/local/bin/gosu.asc \
  && chmod +x /usr/local/bin/gosu; \
  # docker cli(for docker compose config, etc.)
  # https://docs.docker.com/engine/install/ubuntu/
  install -m 0755 -d /etc/apt/keyrings \
  && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
  && chmod a+r /etc/apt/keyrings/docker.gpg \
  && echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "${VERSION_CODENAME}")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null \
  && apt-get update -y \
  && apt-get install -y \
  --no-install-recommends \
  docker-ce="5:${MOBY_VERSION}*" \
  docker-ce-rootless-extras="5:${MOBY_VERSION}*" \
  docker-ce-cli="5:${DOCKER_CLI_VERSION}*" \
  docker-compose-plugin="${DOCKER_COMPOSE_VERSION}*" \
  docker-buildx-plugin="${DOCKER_BUILDX_VERSION}*" \
  containerd.io="${CONTAINERD_VERSION}*"; \
  # release-please
  # https://github.com/googleapis/release-please
  npm install --global \
  "release-please@${RELEASE_PLEASE_VERSION}"; \
  # semantic-release
  # https://github.com/semantic-release/semantic-release
  npm install --global \
  "semantic-release@${SEMANTIC_RELEASE_VERSION}" \
  # @devcontainers/cli
  # https://github.com/devcontainers/cli
  "@devcontainers/cli@${DEVCONTAINERS_CLI_VERSION}"; \
  # direnv
  # https://github.com/direnv/direnv
  go install "github.com/direnv/direnv/v2@v${DIRENV_VERSION}"
WORKDIR "${WORKSPACE}"

# [edge]
ARG FLAKE8_VERSION
ARG BLACK_VERSION
ARG ISORT_VERSION
ARG YAPF_VERSION
ARG PERFLINT_VERSION
ARG BANDIT_VERSION
WORKDIR /tempdir
# hadolint ignore=SC1091,DL3003,DL4001
RUN \
  [[ "${DEVCONTAINER_VERSION}" != "edge" ]] && exit 0; \
  eval "$(pyenv init -)"; \
  # flake8
  # https://github.com/PyCQA/flake8
  pip install --no-cache-dir \
  flake8=="${FLAKE8_VERSION}" \
  # black
  # https://github.com/psf/black
  black=="${BLACK_VERSION}" \
  # isort
  # https://github.com/pycqa/isort
  isort=="${ISORT_VERSION}" \
  # yapf
  # https://github.com/google/yapf
  yapf=="${YAPF_VERSION}" \
  # perflint
  # https://github.com/tonybaloney/perflint
  perflint=="${PERFLINT_VERSION}" \
  # bandit
  # https://github.com/PyCQA/bandit
  bandit=="${BANDIT_VERSION}"
WORKDIR "${WORKSPACE}"

RUN \
  # sudo
  echo "${DEVCONTAINER_USERNAME}" ALL=\(root\) NOPASSWD:ALL > "/etc/sudoers.d/${DEVCONTAINER_USERNAME}" \
  && chmod 0440 "/etc/sudoers.d/${DEVCONTAINER_USERNAME}" \
  # ch
  && chmod 0755 "${DEVCONTAINER_HOME}" \
  && chown -R "${DEVCONTAINER_UID}:${DEVCONTAINER_GID}" "${DEVCONTAINER_HOME}" \
  # cleanup - apt
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  # cleanup - temppdir
  && rm -rf /tempdir \
  # locale
  && locale-gen ja_JP.UTF-8 \
  && localedef -f UTF-8 -i ja_JP ja_JP
ENV LANG="ja_JP.UTF-8"
ENV LANGUAGE="ja_JP:ja"
ENV LC_ALL="ja_JP.UTF-8"

SHELL ["/bin/bash", "-c"]

# [edge]
# hadolint ignore=DL3009,DL4006
RUN \
  --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
  --mount=target=/var/cache/apt,type=cache,sharing=locked \
  rm -f /etc/apt/apt.conf.d/docker-clean; \
  [[ "${DEVCONTAINER_VERSION}" != "edge" ]] && exit 0; \
  apt-get update -y \
  && apt-get upgrade -y \
  && yes | unminimize 2>&1
