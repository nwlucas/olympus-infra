#!/bin/sh
# Pre-start script for vibe-kanban worker container.
# Runs init steps then execs the original worker process.
set -e

# Write vibe-kanban config (host_nickname shown in UI)
CONFIG_DIR="/home/node/.local/share/vibe-kanban"
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/config.json" <<'EOF'
{"config_version":"v8","relay_enabled":true,"host_nickname":"ai-hub"}
EOF

# Clone repos if not already present (Docker volume persists across restarts)
clone_if_missing() {
  local url=$1
  local dest=$2
  if [ ! -d "$dest/.git" ]; then
    git clone "$url" "$dest"
  else
    echo "Skipping $dest — already cloned"
  fi
}

clone_if_missing "https://x-access-token:${GITHUB_OLYMPUS_TOKEN}@github.com/nwlnexus/olympus-sdk" /home/node/olympus-sdk
clone_if_missing "https://github.com/nwlnexus/olympus-infra" /home/node/olympus-infra
clone_if_missing "https://github.com/nwlnexus/olympus-gitops" /home/node/olympus-gitops
clone_if_missing "https://x-access-token:${GITHUB_WORK_TOKEN}@github.com/dtlr/marquee" /home/node/marquee
clone_if_missing "https://x-access-token:${GITHUB_WORK_TOKEN}@github.com/dtlr/formcenter" /home/node/formcenter
clone_if_missing "https://x-access-token:${GITHUB_WORK_TOKEN}@github.com/dtlr/odysseus" /home/node/odysseus
clone_if_missing "https://x-access-token:${GITHUB_WORK_TOKEN}@github.com/dtlr/itpulse" /home/node/itpulse

# Exec the original entrypoint + worker process
exec docker-entrypoint.sh "$@"
