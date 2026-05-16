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

# Clone repos if not already present (Docker volume persists across restarts).
# Clone failures are non-fatal — bad tokens shouldn't crash the worker container;
# users can re-run clones manually after fixing tokens via `docker exec`.
clone_if_missing() {
  local url=$1
  local dest=$2
  if [ ! -d "$dest/.git" ]; then
    if git clone "$url" "$dest" 2>&1; then
      echo "Cloned $dest"
    else
      echo "WARN: failed to clone $dest — continuing without it"
      rm -rf "$dest" 2>/dev/null || true
    fi
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
