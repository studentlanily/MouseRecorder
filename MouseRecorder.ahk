#Requires AutoHotkey v2.0

; ═══════════════════════════════════════════════════════════════
;  Mouse Recorder & Player
;  F9   – Toggle record (start / stop)
;  F10  – Play back recorded mouse data
;  F11  – Pause / resume playback
;  F12  – Stop everything (recording & playback)
; ═══════════════════════════════════════════════════════════════

; ─── Config ───
CoordMode("Mouse", "Screen")
PLAYBACK_SPEED := 1.0       ; 1 = real time, 2 = double speed, 0.5 = half
RECORD_FILE    := A_ScriptDir "\mouse_record.txt"
SAMPLE_MS      := 15        ; ms between recording samples

; ─── Globals ───
g_recording  := false
g_playing    := false
g_paused     := false
g_stopReq    := false

g_events     := []          ; array of {t, x, y, btn}
g_startTick  := 0

g_playIdx    := 0           ; next event index during playback
g_playBase   := 0           ; tick when playback started

; ─── Tray ───
A_IconTip := "Mouse Recorder | F9=Record  F10=Play  F11=Pause  F12=Stop"
TraySetIcon A_AhkPath, 2

; ─── Status overlay ───
sGui := Gui("+AlwaysOnTop +ToolWindow -Caption +Border", "Status")
sGui.SetFont("s10 w700", "Consolas")
sTxt := sGui.Add("Text", "w300 h30 Center 0x200", " Ready")
sGui.Show("xCenter y0 NoActivate")
WinSetTransColor("F0F0F0 180", sGui.Hwnd)
OnExit((*) => sGui.Destroy())

SetStatus(msg, color := "000000") {
    global sTxt
    sTxt.Value := "  " msg
    sTxt.SetFont("c" color)
}

; ─── Hotkeys ───
F9::  ToggleRecord()
F10:: StartPlayback()
F11:: TogglePause()
F12:: StopAll()

; ════════════════════════════════════════
;  RECORD
; ════════════════════════════════════════
ToggleRecord() {
    global g_recording, g_playing, g_events, g_startTick, g_stopReq
    if g_recording {
        StopRecord()
        return
    }
    if g_playing {
        SetStatus("Stop playback first", "FF0000")
        return
    }
    g_events    := []
    g_startTick := DllCall("GetTickCount")
    g_recording := true
    g_stopReq   := false
    SetStatus("● Recording", "FF0000")
    SetTimer RecordTick, SAMPLE_MS
}

StopRecord() {
    global g_recording, g_events
    g_recording := false
    SetTimer RecordTick, 0
    SaveEvents()
    SetStatus("■ Recorded: " g_events.Length " events", "00AA00")
}

RecordTick() {
    global g_recording, g_stopReq, g_startTick, g_events
    if !g_recording or g_stopReq {
        SetTimer RecordTick, 0
        return
    }
    now  := DllCall("GetTickCount")
    elapsed := now - g_startTick

    MouseGetPos(&mx, &my)
    down  := GetKeyState("LButton", "P") ? 1 : 0
    g_events.Push({t: elapsed, x: mx, y: my, btn: down})
}

SaveEvents() {
    global g_events, RECORD_FILE
    buf := ""
    for e in g_events
        buf .= e.t "," e.x "," e.y "," e.btn "`n"
    if FileExist(RECORD_FILE)
        FileDelete(RECORD_FILE)
    FileAppend(buf, RECORD_FILE)
}

; ════════════════════════════════════════
;  PLAYBACK
; ════════════════════════════════════════
StartPlayback() {
    global g_playing, g_recording, RECORD_FILE, g_events
    global g_paused, g_stopReq, g_playIdx, g_playBase, PLAYBACK_SPEED
    if g_playing {
        SetStatus("Already playing", "FFA500")
        return
    }
    if g_recording {
        SetStatus("Stop recording first", "FF0000")
        return
    }
    if !FileExist(RECORD_FILE) {
        SetStatus("No recorded data", "FF0000")
        return
    }
    raw := FileRead(RECORD_FILE)
    lines := StrSplit(Trim(raw, "`r`n"), "`n", "`r")
    g_events := []
    for line in lines {
        p := StrSplit(line, ",")
        if p.Length >= 4
            g_events.Push({t: Integer(p[1]), x: Integer(p[2]), y: Integer(p[3]), btn: Integer(p[4])})
    }
    if g_events.Length = 0 {
        SetStatus("Empty record", "FF0000")
        return
    }

    g_playing  := true
    g_paused   := false
    g_stopReq  := false
    g_playIdx  := 1
    g_playBase := DllCall("GetTickCount")
    g_playBase -= g_events[1].t / PLAYBACK_SPEED
    SetStatus("▶ Looping " g_events.Length " events", "0055FF")
    SetTimer PlaybackTick, 1
}

PlaybackTick() {
    global g_stopReq, g_playing, g_paused, g_playIdx, g_events, g_playBase, PLAYBACK_SPEED
    if g_stopReq or !g_playing {
        SetTimer PlaybackTick, 0
        if g_playing {
            g_playing := false
SetStatus("■ Stopped", "888888")
            g_playIdx := 0
            g_playBase := 0
        }
        return
    }
    if g_paused
        return

    idx := g_playIdx
    if idx > g_events.Length {
        g_playIdx := 1
        g_playBase := DllCall("GetTickCount") - g_events[1].t / PLAYBACK_SPEED
        SetTimer PlaybackTick, 1
        return
    }

    now  := DllCall("GetTickCount")
    target := g_playBase + g_events[idx].t / PLAYBACK_SPEED

    if now < target {
        SetTimer PlaybackTick, Max(1, target - now - 1)
        return
    }

    e := g_events[idx]
    MouseMove(e.x, e.y, 0)
    if e.btn
        Send("{LButton down}")
    else
        Send("{LButton up}")

    g_playIdx++
    SetTimer PlaybackTick, 1
}

; ════════════════════════════════════════
;  PAUSE / RESUME
; ════════════════════════════════════════
TogglePause() {
    global g_playing, g_paused, g_playBase, g_events, g_playIdx, PLAYBACK_SPEED
    if !g_playing {
        SetStatus("Not playing", "888888")
        return
    }
    g_paused := !g_paused
    if g_paused {
        SetStatus("⏸ Paused", "AA00AA")
    } else {
        now := DllCall("GetTickCount")
        g_playBase := now - g_events[g_playIdx].t / PLAYBACK_SPEED
        SetStatus("▶ Resumed", "0055FF")
    }
}

; ════════════════════════════════════════
;  STOP ALL
; ════════════════════════════════════════
StopAll() {
    global g_stopReq, g_recording, g_playing, g_paused, g_playIdx, g_playBase
    g_stopReq    := true
    g_recording  := false
    g_playing    := false
    g_paused     := false
    g_playIdx    := 0
    g_playBase   := 0
    SetTimer RecordTick, 0
    SetTimer PlaybackTick, 0
    SetStatus("■ Stopped", "888888")
}
