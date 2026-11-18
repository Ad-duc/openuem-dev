# =============================================================================
#  Image   : openuem-dev-endpoint
#  Purpose : Disposable Linux endpoint for OpenUEM development. Builds the
#            agent from a fork checkout and runs it in the foreground inside a
#            Debian userland, so inventory, Ansible profiles and APT tasks can
#            be tested without a VM.
#  Context : repository root of openuem-dev, with the agent sources checked
#            out by the workflow under src/openuem-agent.
#  Limits  : no systemd, no desktop session, no openuem-agent-updater. Reboot,
#            power off, VNC/RDP and agent self-update cannot be tested here.
#  Sources : https://github.com/open-uem/openuem-agent (internal/service/linux)
#            https://hub.docker.com/_/golang  https://hub.docker.com/_/debian
# =============================================================================

# --- Build stage: same Go release line as the upstream go.mod (go 1.26.x) ----
FROM golang:1.26 AS build
WORKDIR /src
COPY src/openuem-agent/ ./
# The agent has no cgo dependency: a static binary keeps the runtime image
# independent from the build image libc.
RUN CGO_ENABLED=0 go build -o /out/openuem-agent ./internal/service/linux

# --- Runtime stage ------------------------------------------------------------
FROM debian:13-slim
# ansible        : the agent applies profiles with ansible-playbook (local)
# dmidecode, hwinfo, util-linux (lsblk), iproute2, procps : inventory collectors
# ca-certificates: ansible-galaxy downloads community.general over HTTPS
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ansible ca-certificates dmidecode hwinfo iproute2 procps util-linux \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /out/openuem-agent /usr/bin/openuem-agent
COPY --chmod=755 endpoint/entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
