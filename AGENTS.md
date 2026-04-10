# olympus-infra — Agent Context

Public repo containing Ansible roles and pull-mode playbooks for the Olympus homelab.
This repo is public so `ansible-pull` can run on hosts without credentials.

Push playbooks (with secrets) live in the private `olympus-sdk` sibling repo.

## Repository Structure

```text
olympus-infra/
├── roles/                    # All shared Ansible roles
│   ├── bootstrap-user        # Create ansible user, SSH keys, sudo
│   ├── tailscale             # Install + configure Tailscale
│   ├── k3s                   # Install k3s (single-node or HA)
│   ├── 1password-connect     # Deploy 1Password Connect server
│   ├── traefik               # Traefik ingress (Helm, for standalone hosts)
│   ├── cloudflared           # Cloudflare Tunnel daemon
│   ├── cloudflared-k8s       # cloudflared as k8s Deployment (via Helm)
│   ├── flux                  # Flux CD bootstrap
│   ├── external-secrets      # ESO bootstrap (CRDs + ClusterSecretStore)
│   ├── eso-bootstrap         # ExternalSecret for cluster secrets
│   ├── external-dns          # external-dns Helm deployment
│   ├── cert-manager          # cert-manager Helm deployment
│   ├── ansible-pull          # Configure ansible-pull cron/LaunchDaemon
│   ├── ollama                # Ollama AI inference server (macOS + Linux)
│   ├── homebrew              # Homebrew (macOS)
│   ├── ddclient              # Dynamic DNS client
│   ├── common                # Common OS setup (packages, sysctl, etc.)
│   └── node-prereqs          # k3s node prerequisites
├── playbooks/
│   └── pull/                 # ansible-pull playbooks (run daily on hosts)
│       ├── management-hub.yml
│       ├── ai-hub.yml
│       └── compute-hub.yml
└── inventory/
    ├── group_vars/           # Variables per group (all.yml, management-hub.yml, etc.)
    ├── host_vars/            # Variables per host
    ├── management-hub.yml    # Inventory file (push, from olympus-sdk)
    ├── ai-hub.yml            # Inventory file
    └── compute-hub.yml       # Inventory file
```

## Managed Hosts

| Host | OS | Role |
|---|---|---|
| management-hub | Ubuntu 25.04 | k3s, Flux CD, 1Password Connect, Traefik, cloudflared |
| ai-hub | macOS (Apple Silicon) | Ollama (native, no k8s) |
| compute-hub | Ubuntu (3-node HA) | k3s, Flux CD |

## Variable Naming Conventions

Variables in `group_vars/` and `host_vars/` follow `<role>_<setting>` patterns:

```yaml
tailscale_authkey: "{{ vault_tailscale_authkey }}"
k3s_version: "v1.29.0+k3s1"
ollama_models: [llama3.2, qwen2.5-coder:7b]
flux_version: "v2.3.0"
cloudflared_state: present   # present | absent
```

State variables (`<role>_state: present|absent`) control whether a role installs or removes.

## Adding a New Role

1. Create `roles/<name>/` with standard Ansible structure (`tasks/main.yml`, `defaults/main.yml`, etc.)
2. Add role defaults with sensible values
3. Document any required variables in `defaults/main.yml`
4. Wire into the appropriate push playbook in `olympus-sdk/infra/push-playbooks/`
5. Add group/host vars as needed in `inventory/`

## Testing

Always test roles with `--check` before applying:

```bash
ansible-playbook -i inventory/management-hub.yml playbook.yml --check
ansible-playbook -i inventory/management-hub.yml playbook.yml --diff --check
```

Pull playbooks run daily via ansible-pull on each host — keep them idempotent and fast (health
checks only, no package installs).
