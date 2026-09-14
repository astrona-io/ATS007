#!/usr/bin/env bash
# Installs the crane (registry client) and cosign (signing) CLIs onto the lab host.
set -eu

CRANE_VERSION="v0.20.2"
COSIGN_VERSION="v2.4.0"

# Release assets are published per-architecture; resolve the host's so the
# lab works on both amd64 and arm64 (Apple Silicon) kind nodes.
case "$(uname -m)" in
  x86_64)        CRANE_ARCH="x86_64"; COSIGN_ARCH="amd64" ;;
  aarch64|arm64) CRANE_ARCH="arm64";  COSIGN_ARCH="arm64" ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

echo "Installing crane ${CRANE_VERSION}..."
curl -sSL "https://github.com/google/go-containerregistry/releases/download/${CRANE_VERSION}/go-containerregistry_Linux_${CRANE_ARCH}.tar.gz" \
  -o /tmp/crane.tar.gz
tar -xzf /tmp/crane.tar.gz -C /usr/local/bin crane
rm -f /tmp/crane.tar.gz

echo "Installing cosign ${COSIGN_VERSION}..."
curl -sSL "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-${COSIGN_ARCH}" \
  -o /usr/local/bin/cosign
chmod +x /usr/local/bin/cosign

crane version
cosign version
