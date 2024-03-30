#   Makefile for Icons
#   Copyright (c) 1998-2024 Alexey Ivanov

#       make -B                 Will build Icons.exe
#       make -B -DDEBUG         Will build the debug version of Icons.exe

NAME   = Icons
EXE    = $(NAME).exe
EXE    = $(NAME).exe
EXE_EN = $(NAME).en.exe
EXE_RU = $(NAME).ru.exe
OBJS   = $(NAME).obj

IMPORT = import32

!if $d(DEBUG)
TASMDEBUG=/zi
LINKDEBUG=/v
RCDEBUG=/dDEBUG
!else
TASMDEBUG=
LINKDEBUG=
RCDEBUG=
!endif


RESFILES = resource\merged.en-ru.res

RESFILES_EN = resource\merged.en.res
RESFILES_RU = resource\merged.ru.res


main: $(EXE)

all: $(EXE) $(EXE_EN) $(EXE_RU)

$(EXE): $(OBJS) $(RESFILES)
  tlink32 /Tpe /aa /c /M /s /m $(LINKDEBUG) /L$(LIBPATH) $(OBJS),$(EXE),, $(IMPORT), ,$(RESFILES)

$(EXE_EN): $(OBJS) $(RESFILES_EN)
  tlink32 /Tpe /aa /c /M /s /m $(LINKDEBUG) /L$(LIBPATH) $(OBJS),$(EXE_EN),, $(IMPORT), ,$(RESFILES_EN)

$(EXE_RU): $(OBJS) $(RESFILES_RU)
  tlink32 /Tpe /aa /c /M /s /m $(LINKDEBUG) /L$(LIBPATH) $(OBJS),$(EXE_RU),, $(IMPORT), ,$(RESFILES_RU)


resource\merged.en-ru.res: resource\merged.en-ru.rc
   brcc32 $(RCDEBUG) resource\merged.en-ru.rc

resource\merged.en.res: resource\merged.en.rc
   brcc32 $(RCDEBUG) resource\merged.en.rc

resource\merged.ru.res: resource\merged.ru.rc
   brcc32 $(RCDEBUG) resource\merged.ru.rc


.asm.obj:
   tasm32 /D__tasm__ $(TASMDEBUG) /i$(INCLUDEPATH) /ml $&.asm

.rc.res:
   brcc32 $(RCDEBUG) $&.rc
