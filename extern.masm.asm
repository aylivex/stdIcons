; masm specific
; extern definitions for functions
; and their undecorated names

extrn            ExitProcess@4:PROC
extrn            GetModuleHandleA@4:PROC
extrn            MulDiv@12:PROC

ExitProcess equ ExitProcess@4
GetModuleHandleA equ GetModuleHandleA@4
MulDiv equ MulDiv@12


extrn            BeginPaint@8:PROC
extrn            CreateWindowExA@48:PROC
extrn            DefWindowProcA@16:PROC
extrn            DispatchMessageA@4:PROC
extrn            DrawIcon@16:PROC
extrn            EnableMenuItem@12:PROC
extrn            EndPaint@8:PROC
extrn            GetMessageA@16:PROC
extrn            GetSysColor@4:PROC
extrn            GetSystemMenu@8:PROC
extrn            GetSystemMetrics@4:PROC
extrn            GetSystemMetricsForDpi@8:PROC
extern           GetDpiForWindow@4:PROC
extrn            InsertMenuA@20:PROC
extrn            LoadCursorA@8:PROC
extrn            LoadIconA@8:PROC
extern           LoadImageA@24:PROC
extern           LoadStringA@16:PROC
extrn            MessageBoxA@16:PROC
extrn            PostQuitMessage@4:PROC
extrn            RegisterClassA@4:PROC
extrn            SetWindowPos@28:PROC
extrn            ShowWindow@8:PROC
extrn            TranslateMessage@4:PROC
extrn            UpdateWindow@4:PROC

BeginPaint equ BeginPaint@8
CreateWindowExA equ CreateWindowExA@48
DefWindowProcA equ DefWindowProcA@16
DispatchMessageA equ DispatchMessageA@4
DrawIcon equ DrawIcon@16
EnableMenuItem equ EnableMenuItem@12
EndPaint equ EndPaint@8

GetMessageA equ GetMessageA@16
GetSysColor equ GetSysColor@4
GetSystemMenu equ GetSystemMenu@8
GetSystemMetrics equ GetSystemMetrics@4
GetSystemMetricsForDpi equ GetSystemMetricsForDpi@8
GetDpiForWindow equ GetDpiForWindow@4
InsertMenuA equ InsertMenuA@20
LoadCursorA equ LoadCursorA@8
LoadIconA equ LoadIconA@8
LoadImageA equ LoadImageA@24
LoadStringA equ LoadStringA@16
MessageBoxA equ MessageBoxA@16
PostQuitMessage equ PostQuitMessage@4
RegisterClassA equ RegisterClassA@4
SetWindowPos equ SetWindowPos@28
ShowWindow equ ShowWindow@8
TranslateMessage equ TranslateMessage@4
UpdateWindow equ UpdateWindow@4


extrn            CreateFontIndirectA@4:PROC
extrn            DeleteObject@4:PROC
extrn            GetDeviceCaps@8:PROC
extrn            GetDC@4:PROC
extrn            GetStockObject@4:PROC
extrn            GetTextExtentPoint32A@16:PROC
extrn            ReleaseDC@8:PROC
extrn            SelectObject@8:PROC
extrn            SetBkColor@8:PROC
extrn            TextOutA@20:PROC

CreateFontIndirectA equ CreateFontIndirectA@4
DeleteObject equ DeleteObject@4
GetDeviceCaps equ GetDeviceCaps@8
GetDC equ GetDC@4
GetStockObject equ GetStockObject@4
GetTextExtentPoint32A equ GetTextExtentPoint32A@16
ReleaseDC equ ReleaseDC@8
SelectObject equ SelectObject@8
SetBkColor equ SetBkColor@8
TextOutA equ TextOutA@20


extrn            CreateSolidBrush@4:PROC
extrn            FillRect@12:PROC

CreateSolidBrush equ CreateSolidBrush@4
FillRect equ FillRect@12
