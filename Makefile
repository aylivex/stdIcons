#   Makefile for Icons
#   Copyright (c) 1998-2023 Alexey Ivanov

#       make -B                 Will build Icons.exe
#       make -B -DDEBUG         Will build the debug version of Icons.exe

NAME = Icons
EXE  = $(NAME).exe
OBJS = $(NAME).obj
DEF  = $(NAME).def

!if $d(DEBUG)
TASMDEBUG=/zi
LINKDEBUG=/v
!else
TASMDEBUG=
LINKDEBUG=
!endif

IMPORT=import32


$(EXE): $(OBJS) $(DEF)
  tlink32 /Tpe /aa /c /M /s /m $(LINKDEBUG) $(LIBPATH) $(OBJS),$(EXE),, $(IMPORT), $(DEF)

.asm.obj:
   tasm32 $(TASMDEBUG) $(INCLUDE) /ml $&.asm
