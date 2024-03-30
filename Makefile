#   Makefile for MASM Icons
#   Copyright (c) 2023-2024 Alexey Ivanov

#   nmake /f mkMasm.gmk            Will build Icons.exe
#   nmake /f mkMasm.gmk DEBUG=     Will build the debug version of Icons.exe
#
#   INCLUDEPATH specifies path to include files (win32.inc)

NAME = Icons
EXE  = $(NAME).exe
EXE_EN = $(NAME).en.exe
EXE_RU = $(NAME).ru.exe
OBJS = $(NAME).obj
LIBS = kernel32.lib user32.lib gdi32.lib
VERSION = 3.0

!ifdef DEBUG
MASMDEBUG=/DDEBUG_GRID /Zi
LINKDEBUG=/debug:full
RCDEBUG=/dDEBUG
!else
MASMDEBUG=
LINKDEBUG=/release
RCDEBUG=
!endif

!ifdef LISTING
MASMLISTING=/Fl
!else
MASMLISTING=
!endif

RESFILES = resource\Icons.res resource\Icons.en.res resource\Icons.ru.res resource\Icons.version.en-ru.res resource\Icons.manifest.res

RESFILES_RU = resource\Icons.res resource\Icons.ru.res resource\Icons.version.ru.res resource\Icons.manifest.res
RESFILES_EN = resource\Icons.res resource\Icons.en.res resource\Icons.version.en.res resource\Icons.manifest.res

RC_OPTIONS_EN=$(RCDEBUG) /dRC_ENGLISH
RC_OPTIONS_RU=$(RCDEBUG) /dRC_RUSSIAN
RC_OPTIONS_EN_RU=$(RCDEBUG) /dRC_ENGLISH /dRC_RUSSIAN


main: $(EXE)

all: $(EXE) $(EXE_EN) $(EXE_RU)

$(EXE): $(OBJS) $(RESFILES)
  link /map:$(NAME).map /out:$(EXE) /noimplib /noexp /subsystem:windows,5.01 /version:$(VERSION) /nxcompat $(LINKDEBUG)  $(OBJS) $(LIBS) $(RESFILES)

$(EXE_EN): $(OBJS) $(RESFILES_EN)
  link /map:$(NAME).en.map /out:$(EXE_EN) /noimplib /noexp /subsystem:windows,5.01 /version:$(VERSION) /nxcompat $(LINKDEBUG)  $(OBJS) $(LIBS) $(RESFILES_EN)

$(EXE_RU): $(OBJS) $(RESFILES_RU)
  link /map:$(NAME).ru.map /out:$(EXE_RU) /noimplib /noexp /subsystem:windows,5.01 /version:$(VERSION) /nxcompat $(LINKDEBUG)  $(OBJS) $(LIBS) $(RESFILES_RU)

Icons.asm: extern.masm.asm


resource\Icons.res: resource\Icons.rc
  rc /foresource\Icons.res $(RC_OPTIONS) /n /x resource\Icons.rc

resource\Icons.en.res: resource\Icons.en.rc
  rc /foresource\Icons.en.res /n /x resource\Icons.en.rc

resource\Icons.ru.res: resource\Icons.ru.rc
  rc /foresource\Icons.ru.res /n /x resource\Icons.ru.rc

resource\Icons.version.en.res: resource\Icons.version.rc
  rc /foresource\Icons.version.en.res $(RC_OPTIONS_EN) /n /x resource\Icons.version.rc

resource\Icons.version.ru.res: resource\Icons.version.rc
  rc /foresource\Icons.version.ru.res $(RC_OPTIONS_RU) /n /x resource\Icons.version.rc

resource\Icons.version.en-ru.res: resource\Icons.version.rc
  rc /foresource\Icons.version.en-ru.res $(RC_OPTIONS_EN_RU) /n /x resource\Icons.version.rc

resource\Icons.manifest.res: resource\Icons.exe.manifest resource\Icons.manifest.rc
  rc /foresource\Icons.manifest.res /n /x resource\Icons.manifest.rc


.asm.obj:
  ml /c /Cp /coff /WX /D__masm__ $(MASMDEBUG) $(MASMLISTING) /I$(INCLUDEPATH) $<
