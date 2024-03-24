; Copyright (c) 1998-2024 Alexey Ivanov
;
.386                                    ; Enable 32-bit instructions of 80386
.model flat, stdcall                    ; Model for 32-bit apps and calling convention
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


;
; Initialised data
;
.data
BASE_FONT_SIZE = 9
hFont           dd 0                    ; Handle to the font

bAboutLoaded    db 0                    ; About info loaded?

;
; Constant data (read-only)
;
.const

szClassName     db 'stdIcons32', 0      ; Name of the window class

ALIGN 4

ICON_NUM = 6

; IDs of the icons
IconNames       dd IDI_APPLICATION
                dd IDI_ASTERISK
                dd IDI_EXCLAMATION
                dd IDI_HAND
                dd IDI_QUESTION
                dd IDI_WINLOGO

; IDs in the text form for displaying
Icon1           db 'IDI_APPLICATION', 0
Icon2           db 'IDI_ASTERISK', 0
Icon3           db 'IDI_EXCLAMATION', 0
Icon4           db 'IDI_HAND', 0
Icon5           db 'IDI_QUESTION', 0
Icon6           db 'IDI_WINLOGO', 0

szComCtl32DLL   db 'comctl32.dll', 0
szLoadIconWithScaleDown db 'LoadIconWithScaleDown', 0

ALIGN 4

; Lengths of the icon IDs
IconLen         dd 15
                dd 12
                dd 15
                dd  8
                dd 12
                dd 11

; Pointers to the text icon IDs
IconName        dd offset Icon1
                dd offset Icon2
                dd offset Icon3
                dd offset Icon4
                dd offset Icon5
                dd offset Icon6


;
; Uninitialised data
;
.data?
hInst           dd ?                    ; Handle of the module / process
newhwnd         dd ?                    ; Window handle

dpi             dd ?                    ; Current DPI

ALIGN 4
wc              WNDCLASS    <?>         ; Class of the window

lppaint         PAINTSTRUCT <?>         ; Painting structure
msg             MSGSTRUCT   <?>         ; Message structure

ALIGN 4
WndX            dd ?                    ; Window location and
WndY            dd ?
windowWidth     dd ?                    ; ... size
windowHeight    dd ?

                ; Handles of the loaded icons
hIcons          dd ICON_NUM dup (?)
                ; Widths of the rendered icon text
IconTextWidth   dd ICON_NUM dup (?)
                ; and its height
IconTextHeight  dd ?

                ; The width of the icon
IconWidth       dd ?

                ; Max width of the rendered icon text
IconMaxWidth    dd ?

hComCtlLib      dd ?
LoadIconWithScaleDown dd ?


ifdef DEBUG_GRID
                ; Brush handles to paint grid background
brushMargin     dd ?
brush           dd 4 dup (?)
endif


; Margin around the window edge
MARGIN = 8
; Gap between icon and next icon
ICONS_GAP = 8
; Gap between icon text and its image
TEXT_ICON_GAP = 4


hSysMenu        dd ?                    ; Handle to (system) window menu

txtSize         TEXTSIZE <?>            ; Text size

Font            LOGFONT <?>             ; Logical font

ALIGN 4

; String resource IDs
IDS_TITLE       = 101
IDS_ABOUT_MENU  = 102
IDS_ABOUT_TITLE = 103
IDS_ABOUT_INFO  = 104

IDS_FONT_NAME   = 150

; Size of buffers for strings
WIN_TITLE_BUF   = 128
ABOUT_MENU_BUF  = 128
ABOUT_TITLE_BUF = 128
ABOUT_INFO_BUF  = 1024

szTitleName     db WIN_TITLE_BUF dup (?)    ; Caption of the window
szAboutMenu     db ABOUT_MENU_BUF dup (?)   ; Caption of the menu item
                ; About the program
szAboutTitle    dd ABOUT_TITLE_BUF dup (?)  ; Caption of the About message
szAboutInfo     dd ABOUT_INFO_BUF  dup (?)  ; Text of the About message


;
; Application code
;
.code

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
        mov     [wc.clsLpszMenuName], 0
        mov     [wc.clsLpszClassName], offset szClassName

        push    offset wc
        call    RegisterClassA          ; Register window class


        ; Load the caption for the window
        push    L WIN_TITLE_BUF         ; cchBufferMax
        push    offset szTitleName      ; lpBuffer
        push    L IDS_TITLE             ; uID
        push    [hInst]
        call    LoadStringA

        push    L 00000800h             ; LOAD_LIBRARY_SEARCH_SYSTEM32
        push    L 0
        push    L offset szComCtl32DLL
        call    LoadLibraryExA

        mov     [hComCtlLib], eax

        or      eax, eax
        jz      createWindow

        push    L offset szLoadIconWithScaleDown
        push    eax
        call    GetProcAddress
        mov     [LoadIconWithScaleDown], eax

createWindow:
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

        mov     ebx, [dpi]              ; DPI loaded in WM_CREATE
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

        ; Insert separator
        push    L 0                     ; lpNewItem
        push    L 0                     ; uIDNewItem
        push    L MF_BYPOSITION OR MF_SEPARATOR  ; uFlags
        push    L -1                    ; uPosition
        push    eax                     ; hMenu
        call    InsertMenuA             ; Insert the new item

        ; Load the menu item title
        push    L ABOUT_MENU_BUF        ; cchBufferMax
        push    offset szAboutMenu      ; lpBuffer
        push    L IDS_ABOUT_MENU        ; uID
        push    [hInst]
        call    LoadStringA

        ; Insert the command
        push    offset szAboutMenu      ; lpNewItem
        push    L SC_ABOUT              ; uIDNewItem
        push    L MF_BYPOSITION         ; uFlags
        push    L -1                    ; uPosition
        push    [hSysMenu]              ; hMenu
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
        cmp     [wmsg], 0318h           ; WM_PRINTCLIENT
        je      wmprintclient
        cmp     [wmsg], 02E0h           ; WM_DPICHANGED
        je      wmdpichanged
        cmp     [wmsg], 02E4h           ; WM_GETDPISCALEDSIZE
        je      wmgetdpiscaledsize
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

wmprintclient:
        mov     eax, [wparam]
        call    PaintWindow

        mov     eax, 0                  ; Return code for WM_PRINTCLIENT
        jmp     finish

wmdpichanged:
        mov     esi, [lparam]
        ; Set the new size to the window
        push    L SWP_NOACTIVATE + SWP_NOSENDCHANGING + SWP_NOZORDER
        mov     eax, (RECT PTR [esi]).rcBottom
        mov     ebx, (RECT PTR [esi]).rcTop
        sub     eax, ebx
        push    eax
        ;push    [windowHeight]
        mov     eax, (RECT PTR [esi]).rcRight
        mov     edx, (RECT PTR [esi]).rcLeft
        sub     eax, edx
        push    eax
        ;push    [windowWidth]
        push    ebx
        ;push    (RECT PTR [esi]).rcTop  ; Y
        push    edx
        ;push    (RECT PTR [esi]).rcLeft ; X
        push    L 0                     ; hWndInsertAfter
        push    [hwnd]
        call    SetWindowPos

        mov     eax, 0                  ; Return code for WM_DPICHANGED
        jmp     finish

wmgetdpiscaledsize:
        ; wparam contains a DPI value
        ; lparam pointer to SIZE (TEXTSIZE) structure
        mov     eax, [hwnd]             ; Pass the window handle
        mov     ebx, [wparam]
        and     ebx, 00FFh              ; Preserve lo word only
        call    UpdateFont
        mov     ebx, [wparam]
        and     ebx, 00FFh              ; Preserve lo word only
        call    UpdateWindowSize        ; Calculate the new window size

        call    DestroyIcons
        mov     esi, [IconWidth]
        call    LoadIcons

        mov     esi, [lparam]
        mov     eax, [windowWidth]
        mov     (TEXTSIZE PTR [esi]).tcx, eax
        mov     eax, [windowHeight]
        mov     (TEXTSIZE PTR [esi]).tcy, eax

        mov     eax, 1                  ; The new size is calculated
        jmp     finish

wmcreate:       ; Initialise data for the window
        push    [hwnd]
        call    GetDpiForWindow
        mov     [dpi], eax

        push    eax
        push    L 11 ; SM_CXICON
        call    GetSystemMetricsForDpi

        mov     [IconWidth], eax
        mov     esi, eax

        call    LoadIcons

        mov     eax, 0                  ; Return code for WM_CREATE
        jmp     finish

wmsyscommand:   ; A command in window menu is selected
        cmp     [wparam], SC_ABOUT
        jne     defwndproc

scabout:        ; 'About' command is selected
        mov     al, [bAboutLoaded]
        or      al, al
        jnz     about_loaded

        push    L ABOUT_TITLE_BUF       ; cchBufferMax
        push    offset szAboutTitle     ; lpBuffer
        push    L IDS_ABOUT_TITLE       ; uID
        push    [hInst]
        call    LoadStringA

        push    L ABOUT_INFO_BUF        ; cchBufferMax
        push    offset szAboutInfo      ; lpBuffer
        push    L IDS_ABOUT_INFO        ; IDS_ABOUT_INFO -> uID
        push    [hInst]
        call    LoadStringA

        mov     [bAboutLoaded], 1

about_loaded:
        push    MB_OK OR MB_ICONASTERISK
        push    offset szAboutTitle
        push    offset szAboutInfo
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
; esi = size of the icon
; ebx is used; calling function must preserve ebx
LoadIcons proc
        mov     eax, [LoadIconWithScaleDown]
        test    eax, eax
        ; Use LoadIcons_with_LoadIcon if LoadIconWithScaleDown not available
        jz      LoadIcons_with_LoadIcon

        mov     ebx, ICON_NUM
loadLoop:
        dec     ebx

        lea     eax, hIcons[ebx*4]
        push    eax                     ; phIcon
        push    esi                     ; cy
        push    esi                     ; cx
        push    IconNames[ebx*4]        ; pszName
        push    L 0                     ; hInstance
        call    [LoadIconWithScaleDown]

        test    ebx, ebx
        jnz     loadLoop

        ret
LoadIcons endp

LoadIcons_with_LoadIcon proc
        mov     ebx, ICON_NUM
loadLoop:
        dec     ebx

        push    IconNames[ebx*4]        ; ID of the icon to load
        push    L 0                     ; hInstance
        call    LoadIconA               ; Load the icon
        mov     hIcons[ebx*4], eax      ; Save the icon handle

        test    ebx, ebx
        jnz     loadLoop

        ret
LoadIcons_with_LoadIcon endp

; ebx is used; calling function must preserve ebx
DestroyIcons proc
        mov     ebx, ICON_NUM
destroyLoop:
        dec     ebx

        push    hIcons[ebx*4]           ; hIcon to destroy
        call    DestroyIcon             ; Destroy the icon

        test    ebx, ebx
        jnz     destroyLoop

        ret
DestroyIcons endp

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

        push    L 0003h                 ; diFlags = DI_NORMAL = DI_IMAGE(2) | DI_MASK(1)
        push    L 0                     ; hbrFlickerFreeDraw
        push    L 0                     ; istepIfAniCur
        push    L 0                     ; cyWidth
        push    L 0                     ; cxWidth
        push    hIcons[ebx]             ; Handle of the icon
        push    L MARGIN                ; y
        push    edx                     ; x
        push    [theDC]                 ; Device context
        call    DrawIconEx              ; Draw the icon on the screen

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
; ebx contains the DPI or zero
UpdateFont proc uses ebx edi esi
        LOCAL   hWnd: DWORD
        LOCAL   hDC: DWORD
        LOCAL   oldFont: DWORD

        mov     [hWnd], eax

        ; Get DPI from DC
        push    eax                     ; eax = hWnd
        call    GetDC
        mov     [hDC], eax

        push    L 72
        push    ebx
        push    BASE_FONT_SIZE
        call    MulDiv
        neg     eax
        mov     esi, eax                ; esi stores the height of the font

        mov     eax, [hFont]
        or      eax, eax
        jz      no_font

        push    eax                     ; Delete the old font handle
        call    DeleteObject

no_font:
        ; Create the font
        mov     edi, offset Font        ; Zero LOGFONT structure
        mov     ecx, TYPE Font
        cld
        xor     al, al
        rep     stosb

        mov     [Font.lfHeight], esi
        mov     [Font.lfOrientation], 900
        mov     [Font.lfEscapement], 900
        mov     [Font.lfWeight], 700    ; = FW_BOLD
        mov     [Font.lfCharSet], DEFAULT_CHARSET

        push    L SIZE Font.lfFaceName  ; cchBufferMax
        push    offset Font.lfFaceName  ; lpBuffer
        push    L IDS_FONT_NAME         ; uID
        push    [hInst]
        call    LoadStringA

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
; ebx -> dpi
UpdateWindowSize proc
        push    ebx
        push    L 11 ; SM_CXICON
        call    GetSystemMetricsForDpi

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

        push    ebx
        push    L 8 ; SM_CXFIXEDFRAME
        call    GetSystemMetricsForDpi

        ;       + SM_CXFIXEDFRAME * 2
        mov     edx, eax
        shl     edx, 1
        pop     eax
        add     eax, edx

        push    eax

        push    ebx
        push    L 45 ; SM_CXEDGE
        call    GetSystemMetricsForDpi

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

        push    ebx
        push    L 4 ; SM_CYCAPTION
        call    GetSystemMetricsForDpi

        ;       + SM_CYCAPTION
        pop     edx
        add     edx, eax
        push    edx

        push    ebx
        push    L 8 ; SM_CYFIXEDFRAME
        call    GetSystemMetricsForDpi

        ;       + SM_CYFIXEDFRAME * 2
        pop     edx
        shl     eax, 1
        add     edx, eax
        push    edx

        push    ebx
        push    L 46 ; SM_CYEDGE
        call    GetSystemMetricsForDpi

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
