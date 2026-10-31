[omp-sbx.tar.gz](resources/omp-sbx.tar.gz)

In order to run oh-my-pi inside a Docker Sandbox VM: use this kit & template.

On top, it

* allows accessing localhost:11434 (for local llm access via Ollama)
* allows accessing python and npm urls

`sbx-kit/spec.yaml`

```yaml
schemaVersion: "1"
kind: sandbox
name: omp
displayName: OMP
description: Oh My Pi coding agent running inside a Docker sbx sandbox.

sandbox:
  image: "omp-sbx:latest"
  aiFilename: AGENTS.md
  entrypoint:
    run: [omp]
    args: []
    ttyArgs: []

network:
  allowedDomains:
    - "registry.npmjs.org:443"
    - "pypi.org:443"
    - "files.pythonhosted.org:443"
    - "localhost:11434"

environment:
  variables:
    HOME: "/home/agent"
    PI_CONFIG_DIR: ".omp"
    OLLAMA_HOST: "http://host.docker.internal:11434"

agentContext: |
  ## Sandbox environment

  You are running inside a Docker sbx sandbox.

  The project workspace is mounted at:
    /home/agent/workspace

  OMP persistent state is stored under:
    /home/agent/.omp

  The sandbox provides the isolation boundary and network policy.
```

`Dockerfile`

```sbx-kit/Dockerfile
# syntax=docker/dockerfile:1.7
FROM docker/sandbox-templates:shell-nightly

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential pkg-config libssl-dev curl ca-certificates git jq \
      ripgrep fd-find fzf sqlite3 less procps \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd

USER agent

# OMP's runtime/dependencies.
RUN mkdir -p /home/agent/.local/bin /home/agent/.omp /home/agent/workspace \
    && curl -fsSL https://bun.sh/install | bash
ENV BUN_INSTALL=/home/agent/.bun
ENV PATH="${BUN_INSTALL}/bin:${PATH}"

ARG OMP_VERSION=latest
RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
      x86_64|amd64) omp_arch=x64 ;; \
      aarch64|arm64) omp_arch=arm64 ;; \
      *) echo "unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    if [ "$OMP_VERSION" = "latest" ]; then \
      OMP_VERSION="$(curl -fsSL https://api.github.com/repos/can1357/oh-my-pi/releases/latest \
        | sed -n 's/.*"tag_name":[[:space:]]*"v\([^"]*\)".*/\1/p' | head -1)"; \
    fi; \
    test -n "$OMP_VERSION"; \
    curl -fsSL \
      "https://github.com/can1357/oh-my-pi/releases/download/v${OMP_VERSION}/omp-linux-${omp_arch}" \
      -o /home/agent/.local/bin/omp; \
    chmod +x /home/agent/.local/bin/omp; \
    omp --version

COPY sbx-kit/omp-init.sh /usr/local/bin/omp-init.sh
USER root
RUN chmod +x /usr/local/bin/omp-init.sh
USER agent

ENV HOME=/home/agent \
    PI_CONFIG_DIR=.omp

WORKDIR /home/agent/workspace

LABEL com.docker.sandboxes.flavor="omp"
```

`sbx-kit/omp-init.sh`

```sh
#!/usr/bin/env bash
set -euo pipefail

cd /home/agent/workspace
exec omp "$@"
```

build.sh

```sh
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="${OMP_SBX_IMAGE:-omp-sbx:latest}"
OMP_VERSION="${OMP_VERSION:-latest}"

command -v docker >/dev/null || { echo "error: docker is required" >&2; exit 1; }
command -v sbx >/dev/null || {
  echo "error: Docker sbx CLI is required (install/enable sbx first)" >&2
  exit 1
}

echo "==> building ${IMAGE} (OMP_VERSION=${OMP_VERSION})"
docker build \
  --build-arg "OMP_VERSION=${OMP_VERSION}" \
  -t "${IMAGE}" \
  -f "${ROOT}/sbx-kit/Dockerfile" \
  "${ROOT}"

echo "==> loading image into sbx"
TAR="$(mktemp "${TMPDIR:-/tmp}/omp-sbx.XXXXXX.tar")"
trap 'rm -f "$TAR"' EXIT

docker image save "${IMAGE}" -o "$TAR"
sbx template load "$TAR"

echo "==> smoke test"
NAME="omp-build-verify-$$"
cleanup() { sbx rm -f "$NAME" >/dev/null 2>&1 || true; }
trap cleanup EXIT

sbx create -q \
  --name "$NAME" \
  --kit "${ROOT}/sbx-kit" \
  --template "${IMAGE}" \
  omp /tmp

sleep 2
sbx exec "$NAME" omp --version

echo "✓ OMP sbx template is ready."
echo
echo "Run from a project directory:"
echo "  sbx create --kit \"${ROOT}/sbx-kit\" --template \"${IMAGE}\" omp ."
echo "  sbx run --name omp"
echo
echo "Pin an OMP release if desired:"
echo "  OMP_VERSION=<version> ./build.sh"
```

`README.md`

```md
# omp-sbx

Minimal Docker `sbx` wrapper for [Oh My Pi](https://github.com/can1357/oh-my-pi).

## Build

```bash
./build.sh
```

The build script:

1. builds the custom `omp-sbx:latest` image,
2. saves it as a Docker image archive,
3. loads the archive into `sbx`,
4. creates a temporary sandbox and runs `omp --version`.

The OMP release is resolved at image-build time. Pin it with:

```bash
OMP_VERSION=16.1.15 ./build.sh
```

## Run

From the project you want OMP to work on:

```bash
sbx create \
  --name omp-my-project \
  --kit ./sbx-kit \
  --template omp-sbx:latest \
  omp .

sbx run --name omp-my-project --kit ./sbx-kit
```

The kit starts OMP automatically.

## Persistent OMP state

The kit expects the host's `~/.omp` to be available as an sbx workspace mount and links it to `/home/agent/.omp`. This keeps OMP state outside the microVM.

## Security

Do not mount host credential stores unless you explicitly want the agent to have those credentials. The supplied network policy is intentionally limited to common model/package/GitHub endpoints; add domains only when needed.

`sbx` supplies the actual isolation boundary. Avoid adding Docker privileges, host sockets, `NET_ADMIN`, or broad host mounts to this kit.

```
