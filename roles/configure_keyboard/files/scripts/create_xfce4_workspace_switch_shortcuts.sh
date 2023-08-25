#!/bin/bash
# NOTE: Using xfconf-query to create XFCE4 workspace switching shortcuts as this is the well-known, documented API

# Change to numbered desktops
xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super><Primary>H" -n -t string -s "workspace_1_key"
xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super><Primary>J" -n -t string -s "workspace_2_key"
xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super><Primary>K" -n -t string -s "workspace_3_key"

for i in {4..9}; do
  xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super><Primary>${i}" -n -t string -s "workspace_${i}_key"
done

xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super><Primary>L" -n -t string -s "workspace_10_key"

# Switch to the left or right adjacent desktop
xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super><Primary>Left" -n -t string -s "left_workspace_key"
xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super><Primary>Right" -n -t string -s "right_workspace_key"

# Move the active window to a numbered desktop
xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super><Shift><Primary>H" -n -t string -s "move_window_workspace_1_key"
xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super><Shift><Primary>J" -n -t string -s "move_window_workspace_2_key"
xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super><Shift><Primary>K" -n -t string -s "move_window_workspace_3_key"

for i in {4..9}; do
  xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super><Shift><Primary>${i}" -n -t string -s "move_window_workspace_${i}_key"
done

xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super><Shift><Primary>L" -n -t string -s "move_window_workspace_10_key"

# Move the active window to the adjacent right or left desktop
xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super><Shift><Primary>Left" -n -t string -s "move_window_prev_workspace_key"
xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super><Shift><Primary>Right" -n -t string -s "move_window_next_workspace_key"
