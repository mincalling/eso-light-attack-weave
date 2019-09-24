﻿;This script adds a simple mouse click to each of the enabled keys and optionally a delayed right click.

;========== Do not change this section unless you know what you are doing. ==========
#SingleInstance, force
#NoEnv
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input
SetWorkingDir %A_ScriptDir%
;====================================================================================

;========== CONFIGURATION ==========

;Set this to false if you want the script to start active rather than suspended.
global suspend = true

;Key configuration. Change this if your keybinds differ from the default ones.
global attack := "LButton"
global block := "RButton"
global skillOne := "1"
global skillTwo := "2"
global skillThree := "3"
global skillFour := "4"
global skillFive := "5"
global skillUltimate := "r"
;The default key here is "`" ("``" in the script due to technical reasons for special characters), 
;which changes depending on keyboard layout. 
;So if you use multiple layouts, I recommend changing it to something else, 
;and adjusting the game configuration accordingly.
;For example if you switch to German layout, "`" turns into "ö" in game settings, 
;which is on a different key.
global barSwap := "``"

;Change this to false if you don't want skillFive to be activated when running the script.
global enableFive := true

;If you don't want to weave when using ultimate, set this to false.
global enableUlti := false

;Enable or disable block cancelling on the given skills.
;WARNING: If you enable any of these functions, this macro is more likely to be considered botting.
global enableBlockCancel1 := false
global enableBlockCancel2 := false
global enableBlockCancel3 := false
global enableBlockCancel4 := false
global enableBlockCancel5 := false
global enableBlockCancelU := false

;Change this to false if you want to disable weaving on individual keys, but allow 
;block cancelling to continue.
global enableWeave1 := true
global enableWeave2 := true
global enableWeave3 := true
global enableWeave4 := true
global enableWeave5 := true
global enableWeaveU := false

;Increasing this vaule might help if you see that the light attacks don't go off before the skill.
;Keep this as low as you can for the best result.
global msDelay := 90

;msGlobalCooldown + msDelay must be >= 950 ms.
global msGlobalCooldown := 900

;Both skill and bar swap cooldowns have to be over before you can do a light attack.
;Whichever ends later is considered.
;msBarSwapCooldown + msDelay must be >= 700 ms.
global msBarSwapCooldown := 700

;This determines how many button presses will be executed later if the input comes before
;the global cooldown (GCD) is over. 
;If this is set to 0, you have to time the key presses manually to make sure light attacks go off. 
;Any number greater than that will cause the inputs to be saved and used automatically 
;when the GCD is over. 
;If the queue is full, new presses will override the last performed input.
;queueLength = 1 will result in skill behavior like in ESO by default, but with light attacks in between.
global queueLength := 1

;The following parameters are inactive unless you enabled block cancelling.
;The default values were successfully tested with Endless Hail (Bow skill) at low latency.
;You might want to adjust them depending on what skills you will be cancelling and your internet connection.

;This is used to determine how long to wait, after a skill was used, before blocking.
global msBlockDelay := 500
;This is used to determine how long to hold block once it's triggered.
global msBlockHold := 50
;Global cooldown on skills. Time for which the script will ignore new inputs. 

;========== END OF CONFIGURATION ==========

;Do not change anything starting here, unless you know what you are doing.
global lastSkillActivation := -msGlobalCooldown
global lastLoopIteration := -msGlobalCooldown
global lastBarSwap := -msBarSwapCooldown

global queue := Object()

Hotkey, %skillOne%, s1, On
Hotkey, %skillTwo%, s2, On
Hotkey, %skillThree%, s3, On
Hotkey, %skillFour%, s4, On
Hotkey, %skillFive%, s5, On
Hotkey, %skillUltimate%, su, On
Hotkey, %barSwap%, bs, On

#ifWinActive Elder Scrolls Online

if (suspend) {
    Suspend
}

Tab::
    Suspend
    Loop()
Return

;Control + tab.
^Tab::
    enableFive := !enableFive
return

Loop()
{
    ;If script is suspended, reset queue and stop execution.
    if (A_IsSuspended) {
        ClearQueue()
        return
    }
    
    lastLoopIteration := A_TickCount
    timerDelay := 1
    
    if (queue.MaxIndex() >= 1) {
        skill := lastSkillActivation + msGlobalCooldown
        swap := lastBarSwap + msBarSwapCooldown
        lastRelevantAction := swap > skill ? lastBarSwap : lastSkillActivation
        if (lastRelevantAction + msGlobalCooldown > lastLoopIteration) {
            timerDelay := lastRelevantAction + msGlobalCooldown - lastLoopIteration
        } else {
            W := queue.Remove(1)
            %W%()
        }
    } else {
        timerDelay := msGlobalCooldown
    }
    
    ;Make sure the timerDelay value is always negative
    timerDelay := timerDelay >= 1 ? -timerDelay : -1
    
    ;timerDelay has to be negative to be executed once. Positive values make it periodic.
    SetTimer, Loop, %timerDelay%
}

Schedule(key, enabled, blockCancel, weave)
{
    if (queueLength > 0 && enabled && (blockCancel || weave)) {
        ;Make sure we don't exceed max. queue size.
        qSize := queue.MaxIndex() ? queue.MaxIndex() : 0
        
        if (qSize < queueLength) {
            W := Func("Weave").Bind(key, enabled, blockCancel, weave)
            queue.Push(W)
        } else { ;If queue size is exceeded, override the latest entry (default ESO behavior).
            queue.Pop()
            W := Func("Weave").Bind(key, enabled, blockCancel, weave)
            queue.Push(W)
        }
        
        SetTimer, Loop, Delete
        Loop()
    } else { ;If the GCD is over and the queue is empty, there is no reason to wait.
        Weave(key, enabled, blockCancel, weave)
    }
}

ClearQueue()
{
    ql := queue.MaxIndex()
    while (queue.MaxIndex() >= 1) {
        queue.Remove()
    }
}

;key - the key to activate after weaving. 
;enabled - whether weaving is enabled.
;blockCancel - whether the animation will be block cancelled.
Weave(key, enabled, blockCancel, weave)
{
    if (enabled && weave) {
        if (!GetKeyState(attack) && !GetKeyState(block)) {
            Send, {%attack%}
            Sleep msDelay
        }
    }
    Send, {%key%}
    
    dm := A_TickCount-lastSkillActivation
    OutputDebug, Time since last skill: %dm%
    
    lastSkillActivation := A_TickCount
    if (enabled && blockCancel && !GetKeyState(attack) && !GetKeyState(block)) {
        Sleep msBlockDelay
        if (!GetKeyState(attack) && !GetKeyState(block)) {
            Send, {%block% down}
            Sleep msBlockHold
            Send, {%block% up}
        }
    }
}

s1:
    Schedule(skillOne, true, enableBlockCancel1, enableWeave1)
Return

s2:
    Schedule(skillTwo, true, enableBlockCancel2, enableWeave2)
Return

s3:
    Schedule(skillThree, true, enableBlockCancel3, enableWeave3)
Return

s4:
    Schedule(skillFour, true, enableBlockCancel4, enableWeave4)
Return

s5:
    Schedule(skillFive, enableFive, enableBlockCancel5, enableWeave5)
Return

su:
    Schedule(skillUltimate, enableUlti, enableBlockCancelU, enableWeaveU)
Return

bs:
    ClearQueue()
    lastBarSwap := A_TickCount
    Send, %barSwap%
Return