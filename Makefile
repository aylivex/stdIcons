#   Make file for Icons.
#   Copyright (C) 1998 by Caravan of Love

#       make -B                 Will build wap32.exe
#       make -B -DDEBUG         Will build the debug version of wap32.exe

NAME = Icons
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


$(NAME).EXE: $(OBJS) $(DEF)
  tlink32 /Tpe /aa /c $(LINKDEBUG) $(OBJS),$(NAME),, $(IMPORT), $(DEF)

.asm.obj:
   tasm32 $(TASMDEBUG) /ml $&.asm
