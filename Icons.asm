; Copyright (c) 1998-2023 Alexey Ivanov
;
.386                                    ; Enable 32-bit instructions of 80386
.model flat, STDCALL                    ; Model for 32-bit apps and calling convention
include win32.inc                       ; Consts and structures for Windows

L equ DWORD PTR                         ; Type pointer: 32 bit double-word

; Styles of the window
WndStyle = WS_OVERLAPPED OR WS_CAPTION OR WS_BORDER OR WS_SYSMENU OR WS_MINIMIZEBOX
WndStyleEx = WS_EX_DLGMODALFRAME OR WS_EX_CLIENTEDGE

SC_ABOUT = 1                            ; ID of About command in the window menu

TEXTSIZE STRUC                          ; Structure for getting text size
  tcx dd ?
  tcy dd ?
TEXTSIZE ENDS

;
; External functions from Win32 API
;
ifdef __tasm__
    include extern.tasm.asm
elseifdef __masm__
    include extern.masm.asm
endif

.data            ; Initialised data
newhwnd          dd 0                   ; Window handle
lppaint          PAINTSTRUCT <?>        ; Painting structure
msg              MSGSTRUCT   <?>        ; Message structure
wc               WNDCLASS    <?>        ; Class of the window

hInst            dd 0                   ; Handle of the module / process

.const

szTitleName      db 'Стандартные иконки', 0   ; Caption of the window
szClassName      db 'SHOWICONS32', 0          ; Name of the window class
MenuCaption      db '&О Программе', 0         ; Caption of the menu item
                                 ; About the program
MBInfo           db 'Стандартные иконки', 13, 10, 13, 10
                 db 'Версия 3.0, март 2023 г.', 13, 10
                 db '© 1998-2023 Алексей Иванов', 0

ALIGN 4

ICON_NUM = 6

; IDs of the icons
IconNames        dd IDI_APPLICATION
                 dd IDI_ASTERISK
                 dd IDI_EXCLAMATION
                 dd IDI_HAND
                 dd IDI_QUESTION
                 dd IDI_WINLOGO

; IDs in the text form for displaying
Icon1            db 'IDI_APPLICATION', 0
Icon2            db 'IDI_ASTERISK', 0
Icon3            db 'IDI_EXCLAMATION', 0
Icon4            db 'IDI_HAND', 0
Icon5            db 'IDI_QUESTION', 0
Icon6            db 'IDI_WINLOGO', 0

; Font family for display
FaceName         db 'Arial', 0

ALIGN 4

; Lengths of the icon IDs
IconLen          dd 15
                 dd 12
                 dd 15
                 dd  8
                 dd 12
                 dd 11

; Pointers to the text icon IDs
IconName         dd offset Icon1
                 dd offset Icon2
                 dd offset Icon3
                 dd offset Icon4
                 dd offset Icon5
                 dd offset Icon6

.data?           ; Uninitialised data
WndX             dd ?           ; Window location and
WndY             dd ?
windowWidth      dd ?           ; ... size
windowHeight     dd ?

                 ; Handles of the loaded icons
hIcons           dd ICON_NUM dup (?)
                 ; Widths of the rendered icon text
IconTextWidth    dd ICON_NUM dup (?)
                 ; and its height
IconTextHeight   dd ?

                 ; The width of the icon
IconWidth        dd ?

                 ; Max width of the rendered icon text
IconMaxWidth     dd ?

ifdef DEBUG_GRID
                 ; Brush handles to paint grid background
brushMargin      dd ?
brush            dd 4 dup (?)
endif

BASE_FONT_SIZE = 14
                 ; Handle to the font
hFont            dd ?

; Margin around the window edge
MARGIN = 8
; Gap between icon and next icon
ICONS_GAP = 8
; Gap between icon text and its image
TEXT_ICON_GAP = 4


hSysMenu         dd ?                   ; Handle to (system) window menu

txtSize          TEXTSIZE <?>           ; Text size

Font             LOGFONT <?>            ; Logical font



.code            ; App code

;-----------------------------------------------------------------------------
;
; The starting point of the execution
;
start:

        push    L 0
        call    GetModuleHandleA        ; Get hInstance which is the same
        mov     [hInst], eax            ; as HMODULE

;
; Initialise window class (WndClass)
;
        mov     [wc.clsStyle], CS_HREDRAW + CS_VREDRAW
        mov     [wc.clsLpfnWndProc], offset WndProc
        mov     [wc.clsCbClsExtra], 0
        mov     [wc.clsCbWndExtra], 0

        mov     eax, [hInst]
        mov     [wc.clsHInstance], eax

        ; Load standard app icon as the window icon
        push    L IDI_APPLICATION
        push    L 0
        call    LoadIconA
        mov     [wc.clsHIcon], eax

        ; Cursor for the window
        push    L IDC_ARROW
        push    L 0
        call    LoadCursorA
        mov     [wc.clsHCursor], eax

        mov     [wc.clsHbrBackground], COLOR_BTNFACE + 1
        mov     dword ptr [wc.clsLpszMenuName], 0
        mov     dword ptr [wc.clsLpszClassName], offset szClassName

        push    offset wc
        call    RegisterClassA          ; Register window class


;
; Create window
;
        push    L 0                     ; lpParam
        push    [hInst]                 ; hInstance
        push    L 0                     ; menu
        push    L 0                     ; parent hwnd
        push    L 0                     ; height
        push    L 0                     ; width
        push    L 0                     ; y
        push    L 0                     ; x
        push    L WndStyle              ; Style
        push    offset szTitleName      ; Title string
        push    offset szClassName      ; Class name
        push    L WndStyleEx            ; extra style

        call    CreateWindowExA

        mov     [newhwnd], eax          ; Save the handle to the window

        call    UpdateFont              ; Create the font
                                        ; eax still contains the hWnd

        call    UpdateWindowSize        ; Calculate the window size

;
; Centre the window on the screen
;
        push    L SM_CXSCREEN
        call    GetSystemMetrics
        sub     eax, [windowWidth]      ; (screenWidth - windowWidth)
        shr     eax, 1                  ; / 2
        mov     [WndX], eax

        push    L SM_CYSCREEN
        call    GetSystemMetrics
        sub     eax, [windowHeight]     ; (screenHeight - windowWidth)
        shr     eax, 1                  ; / 2
        mov     [WndY], eax

        ; Position the window and set its size
        push    L SWP_NOACTIVATE + SWP_NOSENDCHANGING + SWP_NOZORDER
        push    [windowHeight]
        push    [windowWidth]
        push    [WndY]
        push    [WndX]
        push    L 0                     ; hWndInsertAfter
        push    [newhwnd]
        call    SetWindowPos

ifdef DEBUG_GRID
;
; Create brushes for grid
;
        push    L 8080FFh
        call    CreateSolidBrush
        mov     [brushMargin], eax

        push    L 80FF80h
        call    CreateSolidBrush
        mov     [brush], eax

        push    L 0FF8080h
        call    CreateSolidBrush
        mov     [brush+4], eax

        push    L 0FF80FFh
        call    CreateSolidBrush
        mov     [brush+8], eax

        push    L 080FFFFh
        call    CreateSolidBrush
        mov     [brush+12], eax
endif ; DEBUG_GRID

;
; Add "About" command into (system) window menu
;
        push    L 0                     ; bRevert (False)
        push    [newhwnd]               ; hWnd
        call    GetSystemMenu           ; Get the handle
        mov     [hSysMenu], eax

        push    offset MenuCaption      ; lpNewItem
        push    L SC_ABOUT              ; uIDNewItem
        push    L MF_BYPOSITION         ; uFlags
        push    L -1                    ; uPosition
        push    eax                     ; hMenu
        call    InsertMenuA             ; Insert the new item

;
; Show the main window
;
        push    L SW_SHOWNORMAL
        push    [newhwnd]
        call    ShowWindow

        ; Paint the window immediately
        push    [newhwnd]
        call    UpdateWindow

;
; Message loop
;
msg_loop:
        push    L 0
        push    L 0
        push    L 0
        push    offset msg
        call    GetMessageA

        cmp     ax, 0
        je      end_loop

        push    offset msg
        call    TranslateMessage

        push    offset msg
        call    DispatchMessageA

        jmp     msg_loop

end_loop:
        push    [msg.msWPARAM]
        call    ExitProcess             ; Terminate the process

        ; end point of the main thread

;-----------------------------------------------------------------------------
WndProc          proc uses ebx edi esi, hwnd:DWORD, wmsg:DWORD, wparam:DWORD, lparam:DWORD
;
; Warning: Win32 requires preserving EBX, EDI and ESI across the calls.
; Let Assembler do it for us via 'uses' keyword
;

        ; Switch between the messages that are handled
        cmp     [wmsg], WM_DESTROY
        je      wmdestroy
        cmp     [wmsg], WM_CREATE
        je      wmcreate
        cmp     [wmsg], WM_PAINT
        je      wmpaint
        cmp     [wmsg], WM_SYSCOMMAND
        je      wmsyscommand

        jmp     defwndproc              ; Call default window procedure
                                        ; for all the other messages

wmpaint:        ; Painting the window
        push    offset lppaint
        push    [hwnd]
        call    BeginPaint              ; Get HDC in eax

        call    PaintWindow             ; Really paint
                                        ; eax -> HDC

        push    offset lppaint
        push    [hwnd]
        call    EndPaint                ; Release HDC

        mov     eax, 0                  ; Return code for WM_PAINT
        jmp     finish

wmcreate:       ; Initialise data for the window
        ; Load the icons
        mov     ecx, ICON_NUM           ; Number of icons
        mov     ebx, 0                  ; Index (offset in arrays)
CreateIcon:
        push    ecx                     ; Preserve the register

        push    IconNames[ebx]          ; ID of the icon to load
        push    L 0                     ; hInstance
        call    LoadIconA               ; Load the icon
        mov     hIcons[ebx], eax        ; Save the icon handle

        pop     ecx                     ; Restore the register

        add     ebx, 4                  ; Next offset in arrays
        loop    CreateIcon

        mov     eax, 0                  ; Return code for WM_PAINT
        jmp     finish

wmsyscommand:   ; A command in window menu is selected
        cmp     [wparam], SC_ABOUT
        jne     defwndproc

scabout:        ; 'About' command is selected
        push    MB_OK OR MB_ICONASTERISK
        push    offset MenuCaption + 1  ; Skip & prefix from menu caption
        push    offset MBInfo
        push    [newhwnd]
        call    MessageBoxA             ; Show the message with short
                                        ; description

        mov     eax, 0                  ; Return code for WM_SYSCOMMAND
        jmp     finish

defwndproc:     ; Unhandled messages
        push    [lparam]
        push    [wparam]
        push    [wmsg]
        push    [hwnd]
        call    DefWindowProcA          ; Default handling
        jmp     finish

wmdestroy:      ; Destroy the window and exit the message loop
        push    L 0
        call    PostQuitMessage

        mov     eax, 0

finish:
        ret
WndProc         endp

;-----------------------------------------------------------------------------
; theDC is passed in eax
PaintWindow proc uses ebx edi esi
        LOCAL    theDC: DWORD
        LOCAL    oldFont: DWORD
        LOCAL    rc: RECT

        mov     [theDC], eax

ifdef DEBUG_GRID
        ; Draw grid
        mov     [rc.rcLeft], 0
        mov     [rc.rcTop], MARGIN
        mov     [rc.rcRight], MARGIN
        mov     eax, IconMaxWidth
        add     eax, MARGIN
        mov     [rc.rcBottom], eax

        push    [brushMargin]           ; Fill left margin
        lea     edi, rc
        push    edi
        push    [theDC]
        call    FillRect

        add     [rc.rcLeft], MARGIN
        mov     [rc.rcTop], 0
        add     [rc.rcBottom], MARGIN

        mov     eax, [IconTextHeight]
        add     [rc.rcRight], eax

        mov     ecx, ICON_NUM
PaintGrid:                              ; Paint background for text, gap,
                                        ; icon and another gap
        lea     esi, brush
        push    ecx

        lodsd                           ; Load the brush from [esi]
        push    eax             
        push    edi
        push    [theDC]
        call    FillRect                ; Text background


        mov     eax, [IconTextHeight]
        add     [rc.rcLeft], eax
        add     [rc.rcRight], eax
        add     [rc.rcRight], TEXT_ICON_GAP

        lodsd                           ; Load the brush from [esi]
        push    eax             
        push    edi
        push    [theDC]
        call    FillRect                ; Gap between text and icon


        add     [rc.rcLeft], TEXT_ICON_GAP
        mov     eax, [IconWidth]
        add     [rc.rcRight], TEXT_ICON_GAP
        add     [rc.rcRight], eax

        lodsd                           ; Load the brush from [esi]
        push    eax             
        push    edi
        push    [theDC]
        call    FillRect                ; Icon background

        mov     eax, [IconWidth]
        add     [rc.rcLeft], eax
        add     [rc.rcRight], eax
        add     [rc.rcRight], ICONS_GAP

        lodsd                           ; Load the brush from [esi]
        push    eax             
        push    edi
        push    [theDC]
        call    FillRect                ; Gap between icon and next text

        add     [rc.rcLeft], ICONS_GAP
        add     [rc.rcRight], ICONS_GAP
        mov     eax, [IconTextHeight]
        add     [rc.rcRight], eax

        pop     ecx
        loop    PaintGrid

        ; The last margin
        sub     [rc.rcLeft], ICONS_GAP
        sub     [rc.rcRight], ICONS_GAP
        add     [rc.rcTop], MARGIN
        sub     [rc.rcBottom], MARGIN

        push    [brushMargin]
        push    edi
        push    [theDC]
        call    FillRect
endif ; DEBUG_GRID


        ; Draw the icons
        mov     ebx, 0                  ; Index (offset) of icon handle

        mov     edx, MARGIN             ; x of the icon
        add     edx, [IconTextHeight]
        add     edx, TEXT_ICON_GAP
        mov     ecx, ICON_NUM           ; Number of icons
DrawIcons:
        push    ecx                     ; Preserve the registers
        push    edx

        push    hIcons[ebx]             ; Handle of the icon
        push    L MARGIN                ; y
        push    edx                     ; x
        push    [theDC]                 ; Device context
        call    DrawIcon                ; Draw the icon on the screen

        pop     edx                     ; Restore the registers
        pop     ecx

        add     ebx,  4                 ; Next hIcon in the array
        add     edx, ICONS_GAP
        add     edx, [IconTextHeight]
        add     edx, [IconWidth]
        add     edx, TEXT_ICON_GAP
        loop    DrawIcons

        ; Draw the text
        push    COLOR_BTNFACE           ; Get the background colour
        call    GetSysColor             ; of buttons (and the window)

        push    eax
        push    [theDC]                 ; Set it as the background
        call    SetBkColor              ; for text

        push    [hFont]                 ; Select the font
        push    [theDC]
        call    SelectObject
        mov     [oldFont], eax          ; Save the old font


        mov     ecx, ICON_NUM           ; Number of icons
        mov     edx, MARGIN             ; x for the text
        mov     ebx, 0                  ; Index (offset) in the array
IconText:
        push    ecx                     ; Preserve the registers
        push    edx

        mov     eax, MARGIN             ; Calculate y:
        add     eax, IconTextWidth[ebx] ; MARGIN + IconTextWidth

        ; Draw the text
        push    IconLen[ebx]            ; Text length
        push    IconName[ebx]           ; Text itself
        push    eax                     ; y
        push    edx                     ; x
        push    [theDC]                 ; Device context
        call    TextOutA

        pop     edx                     ; Restore the registers
        pop     ecx

        add     ebx, 4                  ; Next icon text offset

        add     edx, ICONS_GAP          ; Calculate x of the next text
        add     edx, [IconTextHeight]   ; x + ICONS_GAP + IconTextHeight
        add     edx, [IconWidth]        ; + IconWidth + TEXT_ICON_GAP 
        add     edx, TEXT_ICON_GAP
        loop    IconText

        ; Select the old font into the device context
        push    [oldFont]
        push    [theDC]
        call    SelectObject

        ret
PaintWindow endp

;-----------------------------------------------------------------------------
; Creates the font and measures the text
;
; eax contains the window handle
UpdateFont proc uses ebx edi esi
        LOCAL   hWnd: DWORD
        LOCAL   hDC: DWORD
        LOCAL   oldFont: DWORD

        mov     [hWnd], eax

        push    eax                     ; eax = hWnd
        call    GetDC
        mov     [hDC], eax

        push    L 90                    ; = LOGPIXELSY
        push    eax
        call    GetDeviceCaps

        push    L 72
        push    eax
        push    BASE_FONT_SIZE
        call    MulDiv
        neg     eax
        mov     edx, eax                ; edx stores the height of the font

        ; Create the font
        mov     edi, offset Font        ; Zero LOGFONT structure
        mov     ecx, TYPE Font
        cld
        xor     al, al
        rep     stosb

        mov     [Font.lfHeight], edx
        mov     [Font.lfOrientation], 900
        mov     [Font.lfEscapement], 900
        mov     [Font.lfWeight], 700    ; = FW_BOLD
        mov     [Font.lfCharSet], DEFAULT_CHARSET

        lea     edi, Font.lfFaceName    ; Copy the font family name
        lea     esi, FaceName
        mov     ecx, 7                  ; The length of the font family
        rep     movsb

        push    offset Font
        call    CreateFontIndirectA     ; Create the font

        mov     [hFont], eax            ; and save it in variable

        push    eax                     ; Select the newly created font
        push    [hDC]
        call    SelectObject
        mov     [oldFont], eax          ; Preserve the old font

        ; Measure the text for the icons
        mov     ecx, ICON_NUM           ; Number of icons
        xor     ebx, ebx                ; Index (offset) in the array

MeasureIcons:
        push    ecx                     ; Preserve the counter

        ; Measure a string
        push    offset txtSize
        push    IconLen[ebx]            ; Text length
        push    IconName[ebx]           ; Text itself
        push    [hDC]
        call    GetTextExtentPoint32A

        mov     eax, [txtSize.tcx]      ; Save text width
        mov     IconTextWidth[ebx], eax

        pop     ecx
        add     ebx, 4
        loop    MeasureIcons

        mov     eax, [txtSize.tcy]      ; Save text height
        mov     [IconTextHeight], eax   ; (it's the same for all icons)

        push    [oldFont]               ; Select the old font
        push    [hDC]
        call    SelectObject

        push    [hDC]                   ; Release HDC
        push    [hWnd]
        call    ReleaseDC

        ret

UpdateFont endp

;-----------------------------------------------------------------------------
; Calculates the window size
UpdateWindowSize proc
        push    L 11 ; SM_CXICON
        call    GetSystemMetrics

        mov     [IconWidth], eax

        ; width = (IconTextHeight + TEXT_ICON_GAP
        ;         + IconWidth (= eax) + ICONS_GAP) * ICON_NUM  
        add     eax, [IconTextHeight]
        add     eax, TEXT_ICON_GAP
        add     eax, ICONS_GAP
        mov     edx, ICON_NUM
        mul     edx
        ;       - ICONS_GAP (there's no ICONS_GAP after the last one)
        sub     eax, ICONS_GAP

        ;       + MARGIN * 2
        mov     edx, MARGIN
        shl     edx, 1
        add     eax, edx

        push    eax

        push    L 8 ; SM_CXFIXEDFRAME
        call    GetSystemMetrics

        ;       + SM_CXFIXEDFRAME * 2
        mov     edx, eax
        shl     edx, 1
        pop     eax
        add     eax, edx

        push    eax

        push    L 45 ; SM_CXEDGE
        call    GetSystemMetrics

        ;       + SM_CXEDGE * 2
        mov     edx, eax
        shl     edx, 1
        pop     eax
        add     eax, edx

        mov     [windowWidth], eax

        ; Find the maximum width of the text
        mov     esi, offset IconTextWidth
        mov     edx, [esi]
        add     esi, 4
        mov     ecx, ICON_NUM
        dec     ecx
        cld
MaxTextWidth:        
        lodsd
        cmp     eax, edx
        jle     nextWidth

        mov     edx, eax

nextWidth:
        loop    MaxTextWidth

        ; height = IconMaxWidth ...
        mov     [IconMaxWidth], edx
        push    edx

        push    L 4 ; SM_CYCAPTION
        call    GetSystemMetrics

        ;       + SM_CYCAPTION
        pop     edx
        add     edx, eax
        push    edx

        push    L 8 ; SM_CYFIXEDFRAME
        call    GetSystemMetrics

        ;       + SM_CYFIXEDFRAME * 2
        pop     edx
        shl     eax, 1
        add     edx, eax
        push    edx

        push    L 46 ; SM_CYEDGE
        call    GetSystemMetrics

        ;       + SM_CYEDGE * 2
        pop     edx
        shl     eax, 1
        add     edx, eax

        ;       + MARGIN * 2
        mov     eax, MARGIN
        shl     eax, 1
        add     edx, eax

        mov     [windowHeight], edx

        ret
UpdateWindowSize endp
;-----------------------------------------------------------------------------
end start
