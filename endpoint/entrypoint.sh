#!/usr/bin/env bash
# =============================================================================
#  Script  : entrypoint.sh
#  Purpose : Entry point of the OpenUEM dev endpoint container. Writes the
#            agent configuration on first start, then runs the agent in the
#            foreground (the Linux agent only needs SIGTERM/SIGINT to stop, it
#            does not require systemd).
#  Inputs  : NATS_SERVERS       (required) host:port of the NATS server
#            AGENT_SFTP_PORT    (optional, default 2022)
#            AGENT_VNC_PORT     (optional, default 1443)
#            AGENT_DEBUG        (optional, default true)
#            AGENT_FREQUENCY    (optional, report frequency in minutes, default 5)
#  Files   : /etc/openuem-agent/openuem.ini            created if missing
#            /etc/openuem-agent/certificates/*.cer|key mounted by Compose
# =============================================================================
set -euo pipefail

CONFIG_DIR="/etc/openuem-agent"
CONFIG_FILE="${CONFIG_DIR}/openuem.ini"
CERT_DIR="${CONFIG_DIR}/certificates"

: "${NATS_SERVERS:?NATS_SERVERS env variable needs to be set!}"

mkdir -p "${CONFIG_DIR}" "${CERT_DIR}" /var/log/openuem-agent

# The agent generates its UUID on first start and writes it back to this file,
# so the file is only created when it does not exist yet: recreating it would
# enrol the container as a brand new endpoint at every restart.
if [[ ! -f "${CONFIG_FILE}" ]]; then
  cat > "${CONFIG_FILE}" <<INI
[Agent]
UUID=
Enabled=true
ExecuteTaskEveryXMinutes=5
Debug=${AGENT_DEBUG:-true}
DefaultFrequency=${AGENT_FREQUENCY:-5}
SFTPPort=${AGENT_SFTP_PORT:-2022}
VNCProxyPort=${AGENT_VNC_PORT:-1443}
WingetConfigureFrequency=30
SFTPDisabled=false
RemoteAssistanceDisabled=true

[NATS]
NATSServers=${NATS_SERVERS}

[Certificates]
CACert=${CERT_DIR}/ca.cer
AgentCert=${CERT_DIR}/agent.cer
AgentKey=${CERT_DIR}/agent.key
SFTPCert=${CERT_DIR}/sftp.cer
INI
  echo "[entrypoint] ${CONFIG_FILE} created"
fi

for f in ca.cer agent.cer agent.key sftp.cer; do
  if [[ ! -s "${CERT_DIR}/${f}" ]]; then
    echo "[entrypoint] missing certificate ${CERT_DIR}/${f}" >&2
    exit 1
  fi
done

# The agent logs to a file only: mirror it to stdout for "docker compose logs".
touch /var/log/openuem-agent/openuem-agent.log
tail -n 0 -F /var/log/openuem-agent/*.log &

exec /usr/bin/openuem-agent
