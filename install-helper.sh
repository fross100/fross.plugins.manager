#!/bin/bash
# Detached install helper for omaplug.
#
# Runs `omarchy plugin add` and then, when requested, `omarchy plugin enable`.
# It is launched with setsid/nohup so it survives the plugin reload that
# `omarchy plugin add` triggers at the end (which unloads the manager panel
# itself). Progress is written to $2 so the panel can poll it after reload.
#
# Usage: install-helper.sh <git-url> <status-file> <enable: 0|1>

set -uo pipefail

URL="$1"
STATUS="$2"
ENABLE="$3"
PLUGINS_DIR="$HOME/.config/omarchy/plugins"

write_status() {
  # Avoid symlink race: refuse if STATUS is a symlink
  if [ -L "$STATUS" ]; then
    echo "Refusing to follow symlink for status file: $STATUS" >&2
    exit 1
  fi
  printf '%s\n' "$1" >> "$STATUS"
}

# Securely create/truncate status file without following attacker-controlled symlink.
# The QML caller creates the file via mktemp with 600 perms; we verify it is not a
# symlink and truncate it securely. If the file already exists as a symlink, fail.
umask 077
if [ -L "$STATUS" ]; then
  echo "Refusing to follow symlink for status file: $STATUS" >&2
  exit 1
fi
# Truncate securely: use noclobber to avoid clobbering an existing symlink target
# via race. If noclobber fails, recreate via mktemp and update STATUS for polling.
if ! (set -o noclobber; : > "$STATUS") 2>/dev/null; then
  # File exists and noclobber prevented truncation — try to create a secure replacement
  STATUS_DIR="$(dirname "$STATUS")"
  mkdir -p "$STATUS_DIR" 2>/dev/null || true
  NEW_STATUS="$(umask 077; mktemp "${STATUS%.*}.XXXXXX" 2>/dev/null || mktemp 2>/dev/null || echo "")"
  if [ -n "$NEW_STATUS" ] && [ -f "$NEW_STATUS" ]; then
    # Inform caller via original path that we moved (caller polls original path, so also write there if possible)
    # Instead, fail so caller can retry with secure path; for now, use the new file and symlink original to it securely
    # Create a hard link fallback: just use NEW_STATUS and try to replace original securely
    if [ ! -e "$STATUS" ] || [ -L "$STATUS" ]; then
      rm -f "$STATUS" 2>/dev/null || true
      ln -sf "$NEW_STATUS" "$STATUS" 2>/dev/null || STATUS="$NEW_STATUS"
    else
      STATUS="$NEW_STATUS"
    fi
    : > "$STATUS" 2>/dev/null || true
    chmod 600 "$STATUS" 2>/dev/null || true
  else
    # Fallback: try to truncate with noclobber disabled but after symlink check
    : > "$STATUS" 2>/dev/null || true
    chmod 600 "$STATUS" 2>/dev/null || true
  fi
else
  chmod 600 "$STATUS" 2>/dev/null || true
fi
umask 022
write_status "installing"

out=$(omarchy plugin add "$URL" --yes 2>&1)
rc=$?

printf '%s\n' "$out" >> "$STATUS"

if [[ $rc -ne 0 ]]; then
  write_status "install_failed"
  exit 1
fi

# "Added <id> into <path>" is printed by omarchy-plugin-add before the shell
# reload, so parse the plugin id here, before the reload can interfere.
id=$(printf '%s\n' "$out" | sed -n 's/.*Added \([^ ]*\) into.*/\1/p')
write_status "id=$id"

if [[ -z $id ]]; then
  write_status "install_ok_no_id"
  exit 0
fi

if [[ $ENABLE != 1 ]]; then
  write_status "done"
  exit 0
fi

# The shell reloads its plugin registry after add; wait until it knows the
# plugin, then enable it. Polling here survives the reload because this
# script is detached from the panel.
for _ in $(seq 1 60); do
  if omarchy plugin list --json 2>/dev/null | \
     jq -e --arg id "$id" 'any(.[]; .id == $id)' >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

write_status "enabling"
if omarchy plugin enable "$id" >/dev/null 2>&1; then
  write_status "enabled"
else
  write_status "enable_failed"
fi
write_status "done"