; British - Mac (ISO) characters on top of Windows' "United Kingdom" layout, so a UK PC keyboard types
; the same characters as on macOS. Only applies while the active window uses the United Kingdom layout.
; Remote desktops are left alone: the remote system's own layout handles those keys.
; The Option key reaches these hotkeys as Alt (Kinto remaps it before they see it).
#If !WinActive("ahk_group remotes") && KintoMacGbLayoutActive()
    $+2::Send {U+0040}          ; Shift+2: @            (UK PC: ")
    $!2::Send {U+20AC}          ; Opt+2: €
    $!3::Send {U+0023}          ; Opt+3: #
    $+SC028::Send {U+0022}      ; Shift+': "            (UK PC: @)
    $SC029::Send {U+00A7}       ; Key above Tab: §      (UK PC: `)
    $+SC029::Send {U+00B1}      ; Shift: ±              (UK PC: ¬)
    $SC02B::Send {U+005C}       ; Key left of Enter: \  (UK PC: #)
    $+SC02B::Send {U+007C}      ; Shift: |              (UK PC: ~)
    $SC056::Send {U+0060}       ; Key left of Z: `      (UK PC: \)
    $+SC056::Send {U+007E}      ; Shift: ~              (UK PC: |)
#If

KintoMacGbLayoutActive() {
    threadId := DllCall("GetWindowThreadProcessId", "Ptr", WinExist("A"), "Ptr", 0, "UInt")
    hkl := DllCall("GetKeyboardLayout", "UInt", threadId, "Ptr")
    if (!hkl)
        hkl := DllCall("GetKeyboardLayout", "UInt", 0, "Ptr")
    ; The high word of the HKL identifies the layout; 0x0809 is "United Kingdom".
    return ((hkl >> 16) & 0xFFFF) = 0x0809
}
