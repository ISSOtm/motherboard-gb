
SECTION "Player state machine", ROMX

; Each function must follow the following specification:
; - Return in carry whether the state should be changed (carry set = change it)
; - If carry is set, return next state in `e`
; - Asking to set a state equal to the current one means the state won't be changed, but the animation counter will be reset
PlayerStateMachineFuncs::
    dw PlayerStateStanding
    dw PlayerStateStanding
    dw PlayerStateStanding
    dw PlayerStateStanding
    dw PlayerStateWalkingDown
    dw PlayerStateWalkingUp
    dw PlayerStateWalkingLeft
    dw PlayerStateWalkingRight


; If a button is pressed, change to that (walking) state; otherwise, do nothing
PlayerStateStanding:
    ld hl, wPlayerStateChange
    ld a, [hli]
    and (1 << DOWN_HELD) | (1 << UP_HELD) | (1 << LEFT_HELD) | (1 << RIGHT_HELD)
    ret z ; Carry is clear
    jp CheckNextWalkingState


PlayerStateWalkingDown:
    ; Carry is clear from caller
    ld hl, wPlayerStateChange
    bit DOWN_HELD, [hl]
    ret nz ; Carry is clear
    ld a, [hli]
    and (1 << DOWN_HELD) | (1 << UP_HELD) | (1 << LEFT_HELD) | (1 << RIGHT_HELD)
    jr nz, CheckNextWalkingState
    scf
    ld e, PLAYER_STATE_STANDING_DOWN
    ret

PlayerStateWalkingUp:
    ; Carry is clear from caller
    ld hl, wPlayerStateChange
    bit UP_HELD, [hl]
    ret nz ; Carry is clear
    ld a, [hli]
    and (1 << DOWN_HELD) | (1 << UP_HELD) | (1 << LEFT_HELD) | (1 << RIGHT_HELD)
    jr nz, CheckNextWalkingState
    scf
    ld e, PLAYER_STATE_STANDING_UP
    ret

PlayerStateWalkingLeft:
    ; Carry is clear from caller
    ld hl, wPlayerStateChange
    bit LEFT_HELD, [hl]
    ret nz ; Carry is clear
    ld a, [hli]
    and (1 << DOWN_HELD) | (1 << UP_HELD) | (1 << LEFT_HELD) | (1 << RIGHT_HELD)
    jr nz, CheckNextWalkingState
    scf
    ld e, PLAYER_STATE_STANDING_LEFT
    ret

PlayerStateWalkingRight:
    ; Carry is clear from caller
    ld hl, wPlayerStateChange
    bit RIGHT_HELD, [hl]
    ret nz
    ld a, [hli]
    and (1 << DOWN_HELD) | (1 << UP_HELD) | (1 << LEFT_HELD) | (1 << RIGHT_HELD)
    jr nz, CheckNextWalkingState
    scf
    ld e, PLAYER_STATE_STANDING_RIGHT
    ret

CheckNextWalkingState:
    ld e, PLAYER_STATE_WALKING_DOWN - 1
.seekNextState
    inc e
    add a, a
    jr nc, .seekNextState
    ; Carry is set
    ret
