.386                        ; ������� ������樨 ������ 80386
locals                      ; ������� �ᯮ�짮����� �������� ��६�����
jumps   
.model flat, STDCALL        ; ������ ������ ��� 32����� �ணࠬ�
include win32.inc           ; 32���� ����⠭�� � ��������

L equ <LARGE>               ; �����⥫� ⨯�

; ��� ����
WndStyle = WS_OVERLAPPED OR WS_CAPTION OR WS_BORDER OR WS_SYSMENU OR WS_MINIMIZEBOX
WndStyleEx = WS_EX_DLGMODALFRAME OR WS_EX_CLIENTEDGE

; ������ ����
WND_X_SIZE = 300
WND_Y_SIZE = 138
X_INC = 48

SC_ABOUT = 1                ; �����䨪��� ������� � ����

TSIZE STRUC                 ; ������� ��� ����祭�� ࠧ��஢ ⥪��
  cx dd ?
  cy dd ?
TSIZE ENDS

;
; ��।��塞 ���譨� �㭪樨, ����묨 �� �㤥� ���짮������
;
extrn            BeginPaint:PROC
extrn            CreateFontIndirectA:PROC
extrn            CreateWindowExA:PROC
extrn            DefWindowProcA:PROC
extrn            DeleteObject:PROC
extrn            DispatchMessageA:PROC
extrn            DrawIcon:PROC
extrn            EnableMenuItem:PROC
extrn            EndPaint:PROC
extrn            ExitProcess:PROC
extrn            GetMessageA:PROC
extrn            GetModuleHandleA:PROC
extrn            GetStockObject:PROC
extrn            GetSysColor:PROC
extrn            GetSystemMenu:PROC
extrn            GetSystemMetrics:PROC
extrn            GetTextExtentPoint32A:PROC
extrn            InsertMenuA:PROC
extrn            LoadCursorA:PROC
extrn            LoadIconA:PROC
extrn            MessageBoxA:PROC
extrn            PostQuitMessage:PROC
extrn            RegisterClassA:PROC
extrn            SelectObject:PROC
extrn            SetBkColor:PROC
extrn            ShowWindow:PROC
extrn            TextOutA:PROC
extrn            TranslateMessage:PROC
extrn            UpdateWindow:PROC

;
; ��� �����প� Unicode Win32 ࠧ����� ������� �㭪樨 �� Ansi � Unicode
; 
CreateFontIndirect      equ <CreateFontIndirectA>
CreateWindowEx          equ <CreateWindowExA>
DefWindowProc           equ <DefWindowProcA>
DispatchMessage         equ <DispatchMessageA>
GetMessage              equ <GetMessageA>
GetModuleHandle         equ <GetModuleHandleA>
GetTextExtentPoint      equ <GetTextExtentPoint32A>
InsertMenu              equ <InsertMenuA>
LoadCursor              equ <LoadCursorA>
LoadIcon                equ <LoadIconA>
MessageBox              equ <MessageBoxA>
RegisterClass           equ <RegisterClassA>
TextOut                 equ <TextOutA>

.data            ; ���樠����஢���� �����
; ��ப�, ᮤ�ঠ�� ᮮ�襭�� �� ����᪨� �ࠢ��
copyright        db '(C) Copyright 1998 Caravan of Love',0

newhwnd          dd 0            ; �����䨪��� ����
lppaint          PAINTSTRUCT <?> ; ������� ��� �ᮢ���� ����
msg              MSGSTRUCT   <?> ; ������� ��� ����祭�� ᮮ�饭��
wc               WNDCLASS    <?> ; ����� ����

hInst            dd 0            ; �����䨪��� �����

szTitleName      db '����������� ������', 0   ; ��������� ����
szClassName      db 'SHOWICONS32', 0          ; ��� ��������� �����
MenuCaption      db '&� ���������', 0         ; �������� �㭪� ����
                                 ; ��ப� ���ଠ樨
MBInfo           db '����������� ������', 13, 10, 13, 10
		     db '������ 2.0 �� 19 �������� 1998 �.', 13, 10
                 db '�1998, Caravan of Love�', 0

ALIGN 4

; �����䨪���� ������
IconNames        dd IDI_APPLICATION   
                 dd IDI_ASTERISK
                 dd IDI_EXCLAMATION
                 dd IDI_HAND
                 dd IDI_QUESTION
                 dd IDI_WINLOGO

; �������� ������ ��� �뢮�� �����ᥩ
Icon1            db 'IDI_APPLICATION', 0
Icon2            db 'IDI_ASTERISK', 0
Icon3            db 'IDI_EXCLAMATION', 0
Icon4            db 'IDI_HAND', 0
Icon5            db 'IDI_QUESTION', 0
Icon6            db 'IDI_WINLOGO', 0

FaceName         db 'Arial', 0

ALIGN 4

; ����� ᮮ⢥������ �������� ������
IconLen          dd 15
                 dd 12
                 dd 15
                 dd  8
                 dd 12
                 dd 11

; ���饭�� �������� ������
IconName         dd offset Icon1
                 dd offset Icon2
                 dd offset Icon3
                 dd offset Icon4
                 dd offset Icon5
                 dd offset Icon6

.data?           ; �����樠����஢���� �����
WndX             dd ?           ; ��������� ���� �� �࠭�
WndY             dd ?

hIcons           dd 6 dup (?)   ; �����䨪���� ����㦥���� ������
hFont            dd ?
hSysMenu         dd ?

TextSize         TSIZE <?>      ; ������� ��� ����祭�� ࠧ��� ⥪��
             
Font             LOGFONT <?>    ; ������� ��� ᮧ����� ����


.code            ; ��� �ணࠬ��
;-----------------------------------------------------------------------------
;
; � ��� ��।����� �ࠢ����� �� �����稪�.
;
start:

        push    L 0
        call    GetModuleHandle         ; get hmod (in eax) (�����䨪��� �����)
        mov     [hInst], eax            ; hInstance - � ��, �� � HMODULE
                                        ; � ��� Win32

;
; ���樠����஢��� �������� WndClass (��������� �����)
;
        mov     [wc.clsStyle], CS_HREDRAW + CS_VREDRAW + CS_GLOBALCLASS
        mov     [wc.clsLpfnWndProc], offset WndProc ; ������� ��楤��
        mov     [wc.clsCbClsExtra], 0
        mov     [wc.clsCbWndExtra], 0

        mov     eax, [hInst]
        mov     [wc.clsHInstance], eax

        ; ����㧨�� ������ ��� �ਫ������
        push    L IDI_APPLICATION
        push    L 0
        call    LoadIcon
        mov     [wc.clsHIcon], eax

        ; ����㧨�� ����� ��� �ਫ������
        push    L IDC_ARROW
        push    L 0
        call    LoadCursor
        mov     [wc.clsHCursor], eax

        mov     [wc.clsHbrBackground], COLOR_BTNFACE + 1
        mov     dword ptr [wc.clsLpszMenuName], 0
        mov     dword ptr [wc.clsLpszClassName], offset szClassName

        push    offset wc
        call    RegisterClass           ; ��ॣ����஢��� ������ �����

;
; ������� ࠧ��� �࠭� � ���᫨�� ���न���� ���� �� �࠭�, �⮡�
; ��� �뫮 �ᯮ������ �� 業�� �࠭�
;
        push    L SM_CXSCREEN
        call    GetSystemMetrics
        shr     eax, 1
        sub     eax, WND_X_SIZE / 2
        mov     WndX, eax

        push    L SM_CYSCREEN
        call    GetSystemMetrics
        shr     eax, 1
        sub     eax, WND_Y_SIZE / 2
        mov     WndY, eax

;
; ������� ����
;
        push    L 0                      ; lpParam
        push    [hInst]                  ; hInstance
        push    L 0                      ; menu
        push    L 0                      ; parent hwnd
        push    L WND_Y_SIZE             ; height
        push    L WND_X_SIZE             ; width
        push    L WndY                   ; y
        push    L WndX                   ; x
        push    L WndStyle               ; Style
        push    offset szTitleName       ; Title string
        push    offset szClassName       ; Class name
        push    L WndStyleEx             ; extra style

        call    CreateWindowEx

        mov     [newhwnd], eax           ; ��������� �����䨪��� ����

;**************************************************************************
;*****                      �������㥬 ��⥬��� ����                *****
;**************************************************************************

        ; �������� ������� � ��⥬��� ����
        push    L 0                      ; bRevert (False)
        push    [newhwnd]                ; hWnd
        call    GetSystemMenu            ; ������� �����䨪���
        mov     [hSysMenu], eax

        push    offset MenuCaption       ; lpNewItem
        push    L SC_ABOUT               ; uIDNewItem
        push    L MF_BYPOSITION          ; uFlags
        push    L -1                     ; uPosition
        push    eax                      ; hMenu
        call    InsertMenu               ; �������� ���� �㭪�

        ; ������� ����� � ��������, ����� �� ���室�� ��� ���� 楫��
        push    L MF_GRAYED              
        push    L SC_RESTORE             ; �㭪� "����⠭�����"
        push    [hSysMenu]
        call    EnableMenuItem

        push    L MF_GRAYED
        push    L SC_SIZE                ; �㭪� "������"
        push    [hSysMenu]
        call    EnableMenuItem

        push    L MF_GRAYED
        push    L SC_MAXIMIZE            ; �㭪� "���������"
        push    [hSysMenu]
        call    EnableMenuItem

        ; �������� ����
        push    L SW_SHOWNORMAL
        push    [newhwnd]
        call    ShowWindow

        ; ���ᮢ��� ᮤ�ন��� � ����
        push    [newhwnd]
        call    UpdateWindow

msg_loop: ; ���� ��ࠡ�⪨ ᮮ�饭��
        push    L 0
        push    L 0
        push    L 0
        push    offset msg
        call    GetMessage

        cmp     ax, 0
        je      end_loop

        push    offset msg
        call    TranslateMessage

        push    offset msg
        call    DispatchMessage
                                          
        jmp     msg_loop

end_loop:
        push    [msg.msWPARAM]
        call    ExitProcess       ; �������� �����

        ; �� ������� �� �ਤ�� �

;-----------------------------------------------------------------------------
WndProc          proc uses ebx edi esi, hwnd:DWORD, wmsg:DWORD, wparam:DWORD, lparam:DWORD
;
; ��������: Win32 �ॡ��, �⮡� EBX, EDI � ESI �뫨 ��࠭���!  �� 㤮����-
; ���塞 �⮬� �᫮��� � ������� ����᫥��� ��� ॣ���஢ ��᫥ ��४⨢�
; uses �� ���ᠭ�� ��楤���. �� ��������, �⮡� ��ᥬ���� ��⮬���᪨
; ��࠭�� �� ॣ����� ��� ���
;
        LOCAL theDC: DWORD          ; �����쭠� ��६�����, ᮤ�ঠ��
                                    ;   ���⥪�� ���ன�⢠
        LOCAL oldFont: DWORD

        cmp     [wmsg], WM_DESTROY  ; ��ࠡ��뢠��� ᮮ�饭��
        je      wmdestroy
        cmp     [wmsg], WM_CREATE
        je      wmcreate
        cmp     [wmsg], WM_PAINT
        je      wmpaint
        cmp     [wmsg], WM_SYSCOMMAND
        je      wmsyscommand

        jmp     defwndproc          ; ��� ����ࠡ��뢠���� �ணࠬ���
                                    ;  ᮮ�饭��    

wmpaint:        ; ����ᮢ�� ����
        ; ����� ������
        push    offset lppaint
        push    [hwnd]
        call    BeginPaint
        mov     [theDC], eax

        ; ���ᮢ��� ������
        mov     ebx, 0            ; ������ ������ (ᬥ饭�� �����䨪���)
        mov     edx, 18           ; ��ਧ��⠫쭠� ���न��� ������
        mov     ecx, 6            ; ������⢮ ������
DrawIcons:
        push    ecx               ; ���࠭��� ॣ����� ��� ���쭥�襣�
        push    edx               ;   �ᯮ�짮�����

        push    hIcons[ebx]       ; �����䨪��� ������ 
        push    L 10              ; y
        push    edx               ; x
        push    [theDC]           ; ���⥪�� ���ன�⢠
        call    DrawIcon          ; ���ᮢ��� ������

        pop     edx               ; ����⠭����� ॣ�����
        pop     ecx

        add     ebx,  4           ; ��२�� � ᫥���饩 ������
        add     edx, X_INC           
        loop    DrawIcons

        ; ���ᮢ��� ������

        push    COLOR_BTNFACE     ; ������� 䮭��� 梥� ��� ���� ⠪��
        call    GetSysColor       ;  ��, ��� � 梥� ���      

        push    eax
        push    [theDC]
        call    SetBkColor

        push    [hFont]           ; ����� ᮧ����� ���� � ���⥪��
        push    [theDC]
        call    SelectObject
        mov     [oldFont], eax    ; ���࠭��� ���� ����

        mov     ecx, 6            ; ������⢮ ������
        mov     edx, 2            ; ��ਧ��⠫쭠� ���न��� �뢮�� ⥪��
        mov     ebx, 0            ; ������ � ���ᨢ�
IconText:
        push    ecx               ; ���࠭��� ����� ॣ�����
        push    edx
        push    edx

        ; ������� ࠧ��� ����
        push    offset TextSize
        push    IconLen[ebx]      ; ����� ��ப�
        push    IconName[ebx]     ; ���� ��ப�
        push    [theDC]
        call    GetTextExtentPoint

        pop     edx               ; ����⠭����� ���न���� �� X

        mov     eax, 3            ; ����� ࠧ��� ⥪�� � ���न��� Y
        add     eax, dword ptr TextSize

        ; �뢥�� �������
        push    IconLen[ebx]      ; ����� ��ப�
        push    IconName[ebx]     ; ��ப�
        push    eax               ; y
        push    edx               ; x
        push    [theDC]           ; ���⥪�� ���ன�⢠
        call    TextOut

        pop     edx               ; ����⠭����� ॣ�����
        pop     ecx

        add     ebx, 4            ; ��३� � ᫥���饩 ������
        add     edx, X_INC           
        loop    IconText

        ; ����⠭����� ��室�� ���� � ���⥪��
        push    [oldFont]
        push    [theDC]
        call    SelectObject

        ; �������� ������
        push    offset lppaint
        push    [hwnd]
        call    EndPaint

        mov     eax, 0            ; ������� ��ࠡ�⪨ ᮮ�饭��
        jmp     finish

wmcreate:       ; ����⢨� �� ᮧ����� ����
        ; ����㧨�� ������ (������� �����䨪����)
        mov     ecx, 6            ; ������⢮ ������
        mov     ebx, 0            ; ������ 
CreateIcon:
        push    ecx               ; ���࠭��� ॣ����

        push    IconNames[ebx]    ; �����䨪��� ����� ��� ������
        push    L 0               ; �����䨪��� �����
        call    LoadIcon          ; ����㧨�� ������
        mov     hIcons[ebx], eax  ; ���࠭��� ����祭�� �����䨪���

        pop     ecx               ; ����⠭����� ॣ����

        add     ebx, 4            ; ������騩 ������
        loop    CreateIcon

        ; ������� ���� ����
        mov     edi, offset Font  ; ���㫨�� ᮤ�ন���
        mov     ecx, TYPE Font
        cld
        xor     al, al
        rep     stosb

        mov     [Font.lfHeight], 14
        mov     [Font.lfOrientation], 900
        mov     [Font.lfEscapement], 900
        mov     [Font.lfWeight], FW_BOLD
        mov     [Font.lfCharSet], DEFAULT_CHARSET

        lea     edi, Font.lfFaceName ; �����㥬 ��� ����
        lea     esi, FaceName
        mov     ecx, 7
        rep     movsb

        push    offset Font
        call    CreateFontIndirect

        mov     [hFont], eax

        mov     eax, 0            ; ������� ��ࠡ�⪨ ᮮ�饭��
        jmp     finish

wmsyscommand:
        cmp     [wparam], SC_ABOUT
        je      scabout

        cmp     [wparam], SC_MINIMIZE
        je      scminimize

        cmp     [wparam], SC_RESTORE
        jne     defwndproc        ; ��⠫�� ������� ��⥬���� ����
                                  ;  �� �� ��ࠡ��뢠�� ��-᢮���

        ; ��࠭� ������� "����⠭�����"
        push    L MF_GRAYED       ; ������� �� ������㯭��
        push    L SC_RESTORE      
        push    [hSysMenu]
        call    EnableMenuItem

        push    L MF_ENABLED      ; �� ᤥ���� ����㯭�� 
        push    L SC_MINIMIZE     ;  ������� "�������"
        push    [hSysMenu]
        call    EnableMenuItem

        jmp     defwndproc        ; �맢��� �⠭����� ��ࠡ��稪

scminimize:     ; ��࠭� ������� "�������"
        push    L MF_ENABLED      ; ������� ����㯭�� 
        push    L SC_RESTORE      ;  ������� "����⠭�����"
        push    [hSysMenu]
        call    EnableMenuItem

        push    L MF_GRAYED       ; ������� ������㯭��
        push    L SC_MINIMIZE     ;  ������� "�������"
        push    [hSysMenu]
        call    EnableMenuItem

        jmp     defwndproc        ; �맢��� �⠭����� ��ࠡ��稪

scabout:        ; ��࠭� ������� "� �ணࠬ��"
        push    MB_OK OR MB_ICONASTERISK ; �뢥�� ���� ᮮ�饭��
        push    offset MenuCaption + 1 
        push    offset MBInfo
        push    [newhwnd]
        call    MessageBox

        mov     eax, 0
        jmp     finish

defwndproc:     ; ����ࠡ��뢠��� ᮮ�饭��
        push    [lparam]
        push    [wparam]
        push    [wmsg]
        push    [hwnd]
        call    DefWindowProc     ; �맢��� ������� ��楤�� �� 㬮�砭��
        jmp     finish

wmdestroy:      ; �����襭�� ���� � �����襭�� ࠡ���
        push    L 0
        call    PostQuitMessage

        mov     eax, 0

finish:
        ret
WndProc          endp
;-----------------------------------------------------------------------------
public WndProc
ends
end start

