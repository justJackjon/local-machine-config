#!/bin/bash
# NOTE: Using xfconf-query to manage XFCE4 workspace switching shortcuts as this is the well-known, documented API.
#
# Makes XFCE's custom workspace shortcuts exactly the set below: any other custom shortcut bound to a workspace
# action is removed, and these are set. Prints one line per change and nothing when everything already matches,
# so Ansible reports `changed` only when something changed. With --check, prints what would change without
# changing anything.
#
# NOTE: This replaces a pair of scripts (remove_…/create_…) that deleted every workspace shortcut and recreated
#       it on every run. The removal script's grep pattern used PCRE syntax (`(?:…)`, `.*?`) that `grep -E`
#       doesn't support: it printed `? at start of expression` warnings, which the task counted as a change on
#       every run, and it looped over the shortcut values as well as the property names.
set -euo pipefail

# NOTE: LMC_XFCONF_CHANNEL points the script at a scratch channel, for testing without touching real shortcuts.
channel=${LMC_XFCONF_CHANNEL:-xfce4-keyboard-shortcuts}
check=false
[ "${1:-}" = "--check" ] && check=true

declare -A wanted=(
  # Change to numbered desktops
  ["/xfwm4/custom/<Super><Primary>H"]=workspace_1_key
  ["/xfwm4/custom/<Super><Primary>J"]=workspace_2_key
  ["/xfwm4/custom/<Super><Primary>K"]=workspace_3_key
  ["/xfwm4/custom/<Super><Primary>L"]=workspace_10_key
  # Switch to the left or right adjacent desktop
  ["/xfwm4/custom/<Super><Primary>Left"]=left_workspace_key
  ["/xfwm4/custom/<Super><Primary>Right"]=right_workspace_key
  # Move the active window to a numbered desktop
  ["/xfwm4/custom/<Super><Shift><Primary>H"]=move_window_workspace_1_key
  ["/xfwm4/custom/<Super><Shift><Primary>J"]=move_window_workspace_2_key
  ["/xfwm4/custom/<Super><Shift><Primary>K"]=move_window_workspace_3_key
  ["/xfwm4/custom/<Super><Shift><Primary>L"]=move_window_workspace_10_key
  # Move the active window to the adjacent left or right desktop
  ["/xfwm4/custom/<Super><Shift><Primary>Left"]=move_window_prev_workspace_key
  ["/xfwm4/custom/<Super><Shift><Primary>Right"]=move_window_next_workspace_key
)
for i in {4..9}; do
  wanted["/xfwm4/custom/<Super><Primary>${i}"]="workspace_${i}_key"
  wanted["/xfwm4/custom/<Super><Shift><Primary>${i}"]="move_window_workspace_${i}_key"
done

# Workspace actions: workspace_N_key, move_window_workspace_N_key, and the to/next/prev/left/right variants.
workspace_action='((move_window_)?(to|next|prev|left|right)_workspace|workspace_[0-9]{1,2})_key$'

# Remove custom shortcuts bound to a workspace action that aren't in the wanted set (XFCE's defaults, such as
# <Primary><Alt>Left, and anything left from an earlier configuration).
while read -r path value; do
  [[ "$path" == /xfwm4/custom/* ]] || continue
  [[ "$value" =~ $workspace_action ]] || continue
  [ "${wanted[$path]:-}" = "$value" ] && continue
  $check || xfconf-query -c "$channel" -p "$path" -r
  echo "removed $path ($value)"
done < <(xfconf-query -c "$channel" -lv)

# Set the wanted shortcuts that are missing or bound to something else.
for path in "${!wanted[@]}"; do
  current=$(xfconf-query -c "$channel" -p "$path" 2>/dev/null || true)
  [ "$current" = "${wanted[$path]}" ] && continue
  if ! $check; then
    if [ -n "$current" ]; then
      xfconf-query -c "$channel" -p "$path" -s "${wanted[$path]}"
    else
      xfconf-query -c "$channel" -p "$path" -n -t string -s "${wanted[$path]}"
    fi
  fi
  echo "set $path to ${wanted[$path]}"
done
