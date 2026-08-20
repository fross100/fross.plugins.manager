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
  printf '%s\n' "$1" >> "$STATUS"
}

: > "$STATUS"
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