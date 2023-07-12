#!/bin/bash
# NOTE: Using xfconf-query to remove XFCE4 workspace switching shortcuts as this is the well-known, documented API

regex="/xfwm4/custom/.*?((?:move_window_)?(?:to|next|prev|left|right)_workspace|workspace_[0-9]{1,2})_key$"
paths=$(xfconf-query -c xfce4-keyboard-shortcuts -lv | grep -E "${regex}")

for path in $paths; do
  xfconf-query -c xfce4-keyboard-shortcuts -p $path -r
done
