.386                        ; Разрешить инструкции процессора 80386
locals                      ; Разрешить использование локальных переменных
jumps   
.model flat, STDCALL        ; Задать модель для 32битных программ
include win32.inc           ; 32битные константы и структуры

L equ <LARGE>               ; Указатель типа

; Тип окна
WndStyle = WS_OVERLAPPED OR WS_CAPTION OR WS_BORDER OR WS_SYSMENU OR WS_MINIMIZEBOX
WndStyleEx = WS_EX_DLGMODALFRAME OR WS_EX_CLIENTEDGE

; Размер окна
WND_X_SIZE = 300
WND_Y_SIZE = 138
X_INC = 48

SC_ABOUT = 1                ; Идентификатор команды в меню

TSIZE STRUC                 ; Структура для получения размеров текста
  cx dd ?
  cy dd ?
TSIZE ENDS

;
; Определяем внешние функции, которыми мы будем пользоваться
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
; Для поддержки Unicode Win32 разделяет некоторые функции на Ansi и Unicode
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

.data            ; Инициализированные данные
; Строка, содержащая сообшение об авторских правах
copyright        db '(C) Copyright 1998 Caravan of Love',0

newhwnd          dd 0            ; Идентификатор окна
lppaint          PAINTSTRUCT <?> ; Структура для рисования окна
msg              MSGSTRUCT   <?> ; Структура для получения сообщений
wc               WNDCLASS    <?> ; Класс окна

hInst            dd 0            ; Идентификатор процесса

szTitleName      db 'Стандартные иконки', 0   ; Заголовок окна
szClassName      db 'SHOWICONS32', 0          ; Имя окнонного класса
MenuCaption      db '&О Программе', 0         ; Название пункта меню
                                 ; Строка информации
MBInfo           db 'Стандартные иконки', 13, 10, 13, 10
		     db 'Версия 2.0 от 19 сентября 1998 г.', 13, 10
                 db '©1998, Caravan of Love®', 0

ALIGN 4

; Идентификаторы иконок
IconNames        dd IDI_APPLICATION   
                 dd IDI_ASTERISK
                 dd IDI_EXCLAMATION
                 dd IDI_HAND
                 dd IDI_QUESTION
                 dd IDI_WINLOGO

; Названия иконок для вывода надписей
Icon1            db 'IDI_APPLICATION', 0
Icon2            db 'IDI_ASTERISK', 0
Icon3            db 'IDI_EXCLAMATION', 0
Icon4            db 'IDI_HAND', 0
Icon5            db 'IDI_QUESTION', 0
Icon6            db 'IDI_WINLOGO', 0

FaceName         db 'Arial', 0

ALIGN 4

; Длины соответсвующих названий иконок
IconLen          dd 15
                 dd 12
                 dd 15
                 dd  8
                 dd 12
                 dd 11

; Смещения названий иконок
IconName         dd offset Icon1
                 dd offset Icon2
                 dd offset Icon3
                 dd offset Icon4
                 dd offset Icon5
                 dd offset Icon6

.data?           ; Неинициализированные данные
WndX             dd ?           ; Положение окна на экране
WndY             dd ?

hIcons           dd 6 dup (?)   ; Идентификаторы загруженных иконок
hFont            dd ?
hSysMenu         dd ?

TextSize         TSIZE <?>      ; Структура для получения размера текста
             
Font             LOGFONT <?>    ; Структура для создания шрифта


.code            ; Код программы
;-----------------------------------------------------------------------------
;
; Сюда нам передается управление от загрузчика.
;
start:

        push    L 0
        call    GetModuleHandle         ; get hmod (in eax) (идентификатор модуля)
        mov     [hInst], eax            ; hInstance - то же, что и HMODULE
                                        ; в мире Win32

;
; Инициализировать структуру WndClass (окнонного класса)
;
        mov     [wc.clsStyle], CS_HREDRAW + CS_VREDRAW + CS_GLOBALCLASS
        mov     [wc.clsLpfnWndProc], offset WndProc ; оконная процедура
        mov     [wc.clsCbClsExtra], 0
        mov     [wc.clsCbWndExtra], 0

        mov     eax, [hInst]
        mov     [wc.clsHInstance], eax

        ; Загрузить иконку для приложения
        push    L IDI_APPLICATION
        push    L 0
        call    LoadIcon
        mov     [wc.clsHIcon], eax

        ; Загрузить курсор для приложения
        push    L IDC_ARROW
        push    L 0
        call    LoadCursor
        mov     [wc.clsHCursor], eax

        mov     [wc.clsHbrBackground], COLOR_BTNFACE + 1
        mov     dword ptr [wc.clsLpszMenuName], 0
        mov     dword ptr [wc.clsLpszClassName], offset szClassName

        push    offset wc
        call    RegisterClass           ; Зарегистрировать оконный класс

;
; Получить размер экрана и вычислить координаты окна на экране, чтобы
; оно было расположено по ценру экрана
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
; Создать окно
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

        mov     [newhwnd], eax           ; Запомнить идентификатор окна

;**************************************************************************
;*****                      Редактируем системное меню                *****
;**************************************************************************

        ; Добавить команду в системное меню
        push    L 0                      ; bRevert (False)
        push    [newhwnd]                ; hWnd
        call    GetSystemMenu            ; Получить идентификатор
        mov     [hSysMenu], eax

        push    offset MenuCaption       ; lpNewItem
        push    L SC_ABOUT               ; uIDNewItem
        push    L MF_BYPOSITION          ; uFlags
        push    L -1                     ; uPosition
        push    eax                      ; hMenu
        call    InsertMenu               ; Добавить новый пункт

        ; Запретить доступ к командам, которые не подходят для наших целей
        push    L MF_GRAYED              
        push    L SC_RESTORE             ; Пункт "Восстановить"
        push    [hSysMenu]
        call    EnableMenuItem

        push    L MF_GRAYED
        push    L SC_SIZE                ; Пункт "Размер"
        push    [hSysMenu]
        call    EnableMenuItem

        push    L MF_GRAYED
        push    L SC_MAXIMIZE            ; Пункт "Развернуть"
        push    [hSysMenu]
        call    EnableMenuItem

        ; Показать окно
        push    L SW_SHOWNORMAL
        push    [newhwnd]
        call    ShowWindow

        ; Нарисовать содержимое в окне
        push    [newhwnd]
        call    UpdateWindow

msg_loop: ; Цикл обработки сообщений
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
        call    ExitProcess       ; Завершить процесс

        ; Мы никогда не придем сюда

;-----------------------------------------------------------------------------
WndProc          proc uses ebx edi esi, hwnd:DWORD, wmsg:DWORD, wparam:DWORD, lparam:DWORD
;
; ВНИМАНИЕ: Win32 требует, чтобы EBX, EDI и ESI были сохранены!  Мы удовлет-
; воряем этому условию с помощью перечисления этих регистров после директивы
; uses при описании процедуры. Это делается, чтобы Ассемблер автоматически
; сохранил эти регистры для нас
;
        LOCAL theDC: DWORD          ; Локальная переменная, содержащая
                                    ;   контекст устройства
        LOCAL oldFont: DWORD

        cmp     [wmsg], WM_DESTROY  ; Обрабатываемые сообщения
        je      wmdestroy
        cmp     [wmsg], WM_CREATE
        je      wmcreate
        cmp     [wmsg], WM_PAINT
        je      wmpaint
        cmp     [wmsg], WM_SYSCOMMAND
        je      wmsyscommand

        jmp     defwndproc          ; Для необрабатываемых программой
                                    ;  сообщений    

wmpaint:        ; Перерисовка окна
        ; Начать операцию
        push    offset lppaint
        push    [hwnd]
        call    BeginPaint
        mov     [theDC], eax

        ; Нарисовать иконки
        mov     ebx, 0            ; Индекс иконки (смещение идентификатора)
        mov     edx, 18           ; Горизонтальная координата иконки
        mov     ecx, 6            ; Количество иконок
DrawIcons:
        push    ecx               ; Сохранить регистры для дальнейшего
        push    edx               ;   использования

        push    hIcons[ebx]       ; Идентификатор иконки 
        push    L 10              ; y
        push    edx               ; x
        push    [theDC]           ; Контекст устройства
        call    DrawIcon          ; Нарисовать иконку

        pop     edx               ; Восстановить регистры
        pop     ecx

        add     ebx,  4           ; Переийти к следующей иконке
        add     edx, X_INC           
        loop    DrawIcons

        ; Нарисовать надписи

        push    COLOR_BTNFACE     ; Сделать фоновый цвет для шрифта таким
        call    GetSysColor       ;  же, как и цвет формы      

        push    eax
        push    [theDC]
        call    SetBkColor

        push    [hFont]           ; Выбрать созданный шрифт в контекст
        push    [theDC]
        call    SelectObject
        mov     [oldFont], eax    ; Сохранить старый шрифт

        mov     ecx, 6            ; Количество иконок
        mov     edx, 2            ; Горизонтальная координата вывода текста
        mov     ebx, 0            ; Индекс в массиве
IconText:
        push    ecx               ; Сохранить важные регистры
        push    edx
        push    edx

        ; Получить размер шрифта
        push    offset TextSize
        push    IconLen[ebx]      ; Длина строки
        push    IconName[ebx]     ; Сама строка
        push    [theDC]
        call    GetTextExtentPoint

        pop     edx               ; Восстановить координату по X

        mov     eax, 3            ; Учесть размер текста в координате Y
        add     eax, dword ptr TextSize

        ; Вывести надпись
        push    IconLen[ebx]      ; Длина строки
        push    IconName[ebx]     ; Строка
        push    eax               ; y
        push    edx               ; x
        push    [theDC]           ; Контекст устройства
        call    TextOut

        pop     edx               ; Восстановить регистры
        pop     ecx

        add     ebx, 4            ; Перейти к следующей иконке
        add     edx, X_INC           
        loop    IconText

        ; Восстановить исходный шрифт в контексте
        push    [oldFont]
        push    [theDC]
        call    SelectObject

        ; Завершить операцию
        push    offset lppaint
        push    [hwnd]
        call    EndPaint

        mov     eax, 0            ; Результат обработки сообщения
        jmp     finish

wmcreate:       ; Действия при создании окна
        ; Загрузить иконки (получить идентификаторы)
        mov     ecx, 6            ; Количество иконок
        mov     ebx, 0            ; Индекс 
CreateIcon:
        push    ecx               ; Сохранить регистр

        push    IconNames[ebx]    ; Идентификатор ресурса для иконки
        push    L 0               ; Идентификатор модуля
        call    LoadIcon          ; Загрузить иконку
        mov     hIcons[ebx], eax  ; Сохранить полученный идентификатор

        pop     ecx               ; Восстановить регистр

        add     ebx, 4            ; Следующий индекс
        loop    CreateIcon

        ; Создаем новый шрифт
        mov     edi, offset Font  ; Обнулить содержимое
        mov     ecx, TYPE Font
        cld
        xor     al, al
        rep     stosb

        mov     [Font.lfHeight], 14
        mov     [Font.lfOrientation], 900
        mov     [Font.lfEscapement], 900
        mov     [Font.lfWeight], 700 ; FW_BOLD
        mov     [Font.lfCharSet], DEFAULT_CHARSET

        lea     edi, Font.lfFaceName ; Копируем имя шрифта
        lea     esi, FaceName
        mov     ecx, 7
        rep     movsb

        push    offset Font
        call    CreateFontIndirect

        mov     [hFont], eax

        mov     eax, 0            ; Результат обработки сообщения
        jmp     finish

wmsyscommand:
        cmp     [wparam], SC_ABOUT
        je      scabout

        cmp     [wparam], SC_MINIMIZE
        je      scminimize

        cmp     [wparam], SC_RESTORE
        jne     defwndproc        ; Остальные команды системного меню
                                  ;  мы не обрабатываем по-своему

        ; Выбрана команда "Восстановить"
        push    L MF_GRAYED       ; Сделать ее недоступной
        push    L SC_RESTORE      
        push    [hSysMenu]
        call    EnableMenuItem

        push    L MF_ENABLED      ; Но сделать доступной 
        push    L SC_MINIMIZE     ;  команду "Свернуть"
        push    [hSysMenu]
        call    EnableMenuItem

        jmp     defwndproc        ; Вызвать стандартный обработчик

scminimize:     ; Выбрана команда "Свернуть"
        push    L MF_ENABLED      ; Сделать доступной 
        push    L SC_RESTORE      ;  команду "Восстановить"
        push    [hSysMenu]
        call    EnableMenuItem

        push    L MF_GRAYED       ; Сделать недоступной
        push    L SC_MINIMIZE     ;  команду "Свернуть"
        push    [hSysMenu]
        call    EnableMenuItem

        jmp     defwndproc        ; Вызвать стандартный обработчик

scabout:        ; Выбрана команда "О Программе"
        push    MB_OK OR MB_ICONASTERISK ; Вывести окно сообщения
        push    offset MenuCaption + 1 
        push    offset MBInfo
        push    [newhwnd]
        call    MessageBox

        mov     eax, 0
        jmp     finish

defwndproc:     ; Необрабатываемые сообщения
        push    [lparam]
        push    [wparam]
        push    [wmsg]
        push    [hwnd]
        call    DefWindowProc     ; Вызвать оконную процедру по умолчанию
        jmp     finish

wmdestroy:      ; Разрушение окна и завершение работы
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

