#!/usr/bin/env bash
# init-firewall.sh
# Firewall script that restricts network access at Dev Container startup.
# Reference: https://github.com/anthropics/claude-code/blob/main/.devcontainer/init-firewall.sh
#
# Blocks all outbound traffic except to allow-listed domains, providing a hardened
# environment. Recommended when using --dangerously-skip-permissions.

set -euo pipefail

# ---------- Allow-listed domains ----------
# Add domains required by the project here.
ALLOWED_DOMAINS=(
	# Claude Code / Anthropic
	"api.anthropic.com"
	"sentry.io"
	"statsig.anthropic.com"

	# npm / pnpm
	"registry.npmjs.org"

	# GitHub (plugin fetches and GitHub Releases CDN)
	"github.com"
	"api.github.com"
	"raw.githubusercontent.com"

	# Python (uv / pip)
	"pypi.org"
	"files.pythonhosted.org"

	# Terraform
	"registry.terraform.io"
	"releases.hashicorp.com"
	"checkpoint-api.hashicorp.com"

	# Node.js / distribution (includes the GitHub Releases CDN)
	"nodejs.org"
	"objects.githubusercontent.com"
)

# ---------- Initialize ----------
echo "=== Firewall init ==="

# Save the Docker internal DNS rules so they can be restored
DOCKER_DNS_RULES=""
if iptables -t nat -S 2>/dev/null | grep -q "127.0.0.11"; then
	DOCKER_DNS_RULES=$(iptables -t nat -S | grep "127.0.0.11" || true)
fi

# Clear existing rules
iptables -F OUTPUT 2>/dev/null || true
iptables -F INPUT 2>/dev/null || true
ipset destroy allowed_ips 2>/dev/null || true

# Restore Docker DNS rules
if [[ -n "$DOCKER_DNS_RULES" ]]; then
	echo "$DOCKER_DNS_RULES" | while read -r rule; do
		# shellcheck disable=SC2086
		iptables -t nat ${rule/#-A/-A} 2>/dev/null || true
	done
fi

# ---------- Base rules ----------
# Allow DNS
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allow SSH
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT

# Allow localhost
iptables -A OUTPUT -d 127.0.0.0/8 -j ACCEPT

# Allow established connections
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# ---------- Allow-list ----------
ipset create allowed_ips hash:ip

# Add GitHub IP ranges
echo "Fetching GitHub IP ranges..."
GITHUB_META=$(curl -s https://api.github.com/meta 2>/dev/null || echo "{}")
for key in web git api; do
	echo "$GITHUB_META" | jq -r ".${key}[]? // empty" 2>/dev/null | while read -r cidr; do
		# /32 entries can be added directly; others go through iptables
		if [[ "$cidr" == *"/32" ]]; then
			ipset add allowed_ips "${cidr%/32}" 2>/dev/null || true
		else
			iptables -A OUTPUT -d "$cidr" -j ACCEPT 2>/dev/null || true
		fi
	done
done

# Resolve allow-listed domains and add their IPs
for domain in "${ALLOWED_DOMAINS[@]}"; do
	ips=$(dig +short A "$domain" 2>/dev/null || true)
	for ip in $ips; do
		if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
			ipset add allowed_ips "$ip" 2>/dev/null || true
		fi
	done
done

# Detect and allow the host network
HOST_IP=$(ip route | grep default | awk '{print $3}' || true)
if [[ -n "$HOST_IP" ]]; then
	HOST_NETWORK="${HOST_IP%.*}.0/24"
	iptables -A OUTPUT -d "$HOST_NETWORK" -j ACCEPT
fi

# Allow IPs from the allow-list
iptables -A OUTPUT -m set --match-set allowed_ips dst -j ACCEPT

# ---------- Default deny ----------
iptables -A OUTPUT -j DROP

# ---------- Verify ----------
echo "Verifying firewall rules..."

# Confirm that a domain expected to be blocked is in fact blocked
if curl -s --connect-timeout 3 https://example.com >/dev/null 2>&1; then
	echo "WARNING: connection to example.com is not blocked" >&2
else
	echo "OK: external access is restricted"
fi

# Confirm that an allow-listed domain is reachable
if curl -s --connect-timeout 5 https://api.github.com >/dev/null 2>&1; then
	echo "OK: allow-listed domain (api.github.com) is reachable"
else
	echo "WARNING: cannot reach allow-listed domains" >&2
fi

echo "=== Firewall init complete ==="
