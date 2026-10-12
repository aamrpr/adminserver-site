#!/usr/bin/env bash
# AdminServer — one-command installer.
# Downloads the latest release from the official channel, checks its SHA-256,
# and runs the full installer. Updates afterwards are one click inside the
# panel and are Ed25519-signature-verified.
#
#   curl -fsSL https://aamrpr.github.io/adminserver-site/install.sh | sudo bash
#   # another port (first install): curl -fsSL .../install.sh | sudo PANEL_PORT=9443 bash
set -euo pipefail

CH="https://aamrpr.github.io/adminserver-site/dl"
die() { echo "خطأ / Error: $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "شغّله بصلاحية root / run as root:  curl -fsSL ${CH%/dl}/install.sh | sudo bash"
for t in curl tar sha256sum; do command -v "$t" >/dev/null 2>&1 || die "$t is required"; done

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

echo "==> AdminServer: reading the latest release…"
curl -fsSL --max-time 30 "$CH/version.json" -o "$tmp/v.json" || die "cannot reach the release channel"
ver="$(grep -o '"version"[^,}]*' "$tmp/v.json" | head -1 | cut -d'"' -f4)"
sha="$(grep -o '"sha256"[^,}]*'  "$tmp/v.json" | head -1 | cut -d'"' -f4)"
url="$(grep -o '"url"[^,}]*'     "$tmp/v.json" | head -1 | cut -d'"' -f4)"
[ -n "$ver" ] && [ -n "$sha" ] && [ -n "$url" ] || die "the release manifest is malformed"

echo "==> downloading AdminServer $ver…"
curl -fsSL --max-time 600 "$url" -o "$tmp/pkg.tar.gz" || die "download failed"
echo "$sha  $tmp/pkg.tar.gz" | sha256sum -c - >/dev/null 2>&1 || die "checksum mismatch — refusing to install"

mkdir -p "$tmp/x"
tar -xzf "$tmp/pkg.tar.gz" -C "$tmp/x" --strip-components=1 || die "could not unpack the package"
[ -x "$tmp/x/install.sh" ] || die "the package has no installer"

echo "==> running the installer…"
cd "$tmp/x"
bash ./install.sh
