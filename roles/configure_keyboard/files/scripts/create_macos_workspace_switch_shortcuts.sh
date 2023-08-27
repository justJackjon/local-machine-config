#!/bin/bash

PATH_TO_PLIST=~/Library/Preferences/com.apple.symbolichotkeys.plist
MODIFIER_CTRL_CMD=1310720
MODIFIER_CTRL_CMD_ARROW=11796480
MODIFIER_SHIFT_CTRL_CMD_ARROW=11927552
NO_ASCII_VALUE=65535

declare -A ASCII_CODES=(
    ["h"]=104
    ["j"]=106
    ["k"]=107
    ["4"]=52
    ["5"]=53
    ["6"]=54
    ["7"]=55
    ["8"]=56
    ["9"]=57
    ["l"]=108
)

declare -A KEY_CODES=(
    ["h"]=4
    ["j"]=38
    ["k"]=40
    ["4"]=21
    ["5"]=23
    ["6"]=22
    ["7"]=26
    ["8"]=28
    ["9"]=25
    ["l"]=37
    ["left"]=123
    ["right"]=124
)

declare -A KEYCODES_PARAMS=(
    # CTRL + CMD + H = Switch to desktop 1
    [118]="${ASCII_CODES[h]} ${KEY_CODES[h]} $MODIFIER_CTRL_CMD"
    
    # CTRL + CMD + J = Switch to desktop 2
    [119]="${ASCII_CODES[j]} ${KEY_CODES[j]} $MODIFIER_CTRL_CMD"
    
    # CTRL + CMD + K = Switch to desktop 3
    [120]="${ASCII_CODES[k]} ${KEY_CODES[k]} $MODIFIER_CTRL_CMD"
    
    # CTRL + CMD + 4 = Switch to desktop 4
    [121]="${ASCII_CODES[4]} ${KEY_CODES[4]} $MODIFIER_CTRL_CMD"
    
    # CTRL + CMD + 5 = Switch to desktop 5
    [122]="${ASCII_CODES[5]} ${KEY_CODES[5]} $MODIFIER_CTRL_CMD"
    
    # CTRL + CMD + 6 = Switch to desktop 6
    [123]="${ASCII_CODES[6]} ${KEY_CODES[6]} $MODIFIER_CTRL_CMD"
    
    # CTRL + CMD + 7 = Switch to desktop 7
    [124]="${ASCII_CODES[7]} ${KEY_CODES[7]} $MODIFIER_CTRL_CMD"
    
    # CTRL + CMD + 8 = Switch to desktop 8
    [125]="${ASCII_CODES[8]} ${KEY_CODES[8]} $MODIFIER_CTRL_CMD"
    
    # CTRL + CMD + 9 = Switch to desktop 9
    [126]="${ASCII_CODES[9]} ${KEY_CODES[9]} $MODIFIER_CTRL_CMD"
    
    # CTRL + CMD + L = Switch to desktop 10
    [127]="${ASCII_CODES[l]} ${KEY_CODES[l]} $MODIFIER_CTRL_CMD"

    # CTRL + CMD + Left Arrow = Move left a space
    [79]="$NO_ASCII_VALUE ${KEY_CODES[left]} $MODIFIER_CTRL_CMD_ARROW"

    # CTRL + CMD + Right Arrow = Move right a space
    [81]="$NO_ASCII_VALUE ${KEY_CODES[right]} $MODIFIER_CTRL_CMD_ARROW"

    # NOTE: The following hotkeys are modified in the plist file when changing the 'Move
    # left/right a space' shortcuts from the Keyboard Settings UI. They do not appear to
    # be used for anything (yet) but are included here so that we ensure we replicate the
    # same behaviour as the UI when changing the hotkeys. Given the shift modifier is used,
    # it is possible that these hotkeys will be used to move the current window left/right.

    # SHIFT + CTRL + CMD + Left Arrow = Unkown, suspected to move the current window left.
    [80]="$NO_ASCII_VALUE ${KEY_CODES[left]} $MODIFIER_SHIFT_CTRL_CMD_ARROW"

    # SHIFT + CTRL + CMD + Right Arrow = Unknown, suspected to move the current window right.
    [82]="$NO_ASCII_VALUE ${KEY_CODES[right]} $MODIFIER_SHIFT_CTRL_CMD_ARROW"
)

# Backup the plist
cp "$PATH_TO_PLIST" "${PATH_TO_PLIST}.bak"

# Modify the plist for each keycode
for KEY in "${!KEYCODES_PARAMS[@]}"; do
    # Check if the key exists
    /usr/libexec/PlistBuddy -c "Print :AppleSymbolicHotKeys:$KEY" "$PATH_TO_PLIST" &>/dev/null

    if [ $? -eq 0 ]; then
        /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:$KEY:enabled 1" "$PATH_TO_PLIST"

        PARAMS=(${KEYCODES_PARAMS[$KEY]})
        /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:$KEY:value:parameters:0 ${PARAMS[0]}" "$PATH_TO_PLIST"
        /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:$KEY:value:parameters:1 ${PARAMS[1]}" "$PATH_TO_PLIST"
        /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:$KEY:value:parameters:2 ${PARAMS[2]}" "$PATH_TO_PLIST"
    fi
done

# Refresh the in-memory cache
defaults read com.apple.symbolichotkeys.plist > /dev/null

# Apply the updated settings
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

echo "Hotkeys updated. Original plist backed up as ${PATH_TO_PLIST}.bak"
