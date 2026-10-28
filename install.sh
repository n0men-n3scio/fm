#!/bin/bash
set -euo pipefail
base=/workspace/.local/fm-php
mkdir -p "$base/apt/lists/partial" "$base/apt/archives/partial" "$base/apt/empty" "$base/root" /workspace/.local/bin
cat > "$base/apt/apt.conf" <<'CONF'
Dir::Etc::Parts "/workspace/.local/fm-php/apt/empty";
Dir::Etc::main "-";
Dir::Etc::sourcelist "/workspace/.local/fm-php/apt/sources.list";
Dir::Etc::sourceparts "/workspace/.local/fm-php/apt/empty";
Dir::State::lists "/workspace/.local/fm-php/apt/lists";
Dir::State::status "/workspace/.local/fm-php/apt/status";
Dir::Cache::archives "/workspace/.local/fm-php/apt/archives";
APT::Sandbox::User "agent";
CONF
cat > "$base/apt/sources.list" <<'SOURCES'
deb [signed-by=/usr/share/keyrings/debian-archive-keyring.gpg] https://deb.debian.org/debian trixie main
deb [signed-by=/usr/share/keyrings/debian-archive-keyring.gpg] https://deb.debian.org/debian-security trixie-security main
SOURCES
touch "$base/apt/status"
export APT_CONFIG="$base/apt/apt.conf"
/usr/bin/apt-get update
/usr/bin/apt-get install --download-only --no-install-recommends -y php8.4-cli php8.4-mbstring php8.4-zip
for pkg in "$base"/apt/archives/*.deb; do dpkg-deb -x "$pkg" "$base/root"; done
cat > /workspace/.local/bin/php <<'WRAPPER'
#!/bin/sh
base=/workspace/.local/fm-php/root
exec "$base/usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2" --library-path "$base/usr/lib/x86_64-linux-gnu" "$base/usr/bin/php8.4" -n -d "extension_dir=$base/usr/lib/php/20240924" -d extension=mbstring -d extension=fileinfo -d extension=zip -d extension=iconv -d date.timezone=UTC "$@"
WRAPPER
chmod +x /workspace/.local/bin/php
/workspace/.local/bin/php -r 'foreach (["mbstring","fileinfo","zip","iconv"] as $module) { if (!extension_loaded($module)) exit(1); }'
cd /workspace/fm
/workspace/.local/bin/php -l index.php
