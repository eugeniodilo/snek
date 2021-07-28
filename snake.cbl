              >> SOURCE FORMAT IS FREE
REPLACE ==:BCOL:== BY ==with BACKGROUND-COLOR==
        ==:FCOL:== BY ==FOREGROUND-COLOR==.
*>****************************************************************
*> Purpose:    Snake game written in GnuCOBOL
*> Author:     source restructured by E.Di Lorenzo from original at https://github.com/lewisjb/snek
*>             deleted ncurses calls to read/write screen and other enhancements, now pure GnuCOBOL
*> Tectonics:  cobc -x GC99SNAKE.COB -lpdcurses (compile with GnuCOBOL 3.1 or greater)
*> CALLS;      GC01BOX.DLL (compile from GC01BOX.COB)
*> Parameters: none
*> License:    GNU Lesser General Public License
*> Version:    1.0 2021.07.01
*> Changelog:  1.0 first release.
*>
*> Playing:  gc99snake
*> The game is on a 13x13 grid with wrap-around.
*> The snake starts in the top-left and moves downward.
*> Currently the food spawning locations will always be the same.
*> Controls: cursor keys are used to move the snake aroundand on food,
*> ESCAPE will exit the game
*>****************************************************************
IDENTIFICATION DIVISION.
program-id. GC99SNAKE.

ENVIRONMENT DIVISION.
configuration section.
special-names.
    CRT STATUS IS wCRT-STATUS.    *> Return Code from Accept (ex.PF Keys, Mouse Keys)
    CURSOR     IS wCursorRowCol.  *> Cursor Position

*>****************************************************************
*>
*>****************************************************************
DATA DIVISION.
working-storage section.
01 black   constant as 0.
01 blue    constant as 1.
01 green   constant as 2.
01 cyan    constant as 3.
01 red     constant as 4.
01 magenta constant as 5.
01 yellow  constant as 6.
01 white   constant as 7.

*> Visual symbols
78 wFieldChar1 value '.'.
01 wFieldChar pic x value space.
01 wSnakeChar pic x value space.
01 wFoodChar  pic x value space.

78 wFieldChar-bco value green.
78 wFieldChar-fco value white.
78 wSnakeChar-bco value black.
78 wSnakeChar-fco value yellow.
78 wFoodChar-bco  value green.
78 wFoodChar-fco  value red.
78 wBox-bco       value red.
78 wBox-fco       value white.

*>Constant codes for cur-direction
01 DIR-UP    pic 9(1) value 1.
01 DIR-LEFT  pic 9(1) value 2.
01 DIR-DOWN  pic 9(1) value 3.
01 DIR-RIGHT pic 9(1) value 4.

01 wBaseLin    PIC 9(03) value 05.
01 wBaseCol    PIC 9(03) value 10.
01 wLin        PIC 9(03) value zero.
01 wCol        PIC 9(03) value zero.
01 wIndRow     PIC 9(03) value zero.
01 wIndCol     PIC 9(03) value zero.

01 old-direction pic 9(1) value 3.
01 cur-direction pic 9(1) value 3.

*> The snake, board is 13 (ROW) x 20 (COL)  max-length is 260
01 snake.
   05 snakePart occurs 260 indexed by snakeIdx.
      10 snakeRow pic 9(2).
      10 snakeCol pic 9(2).
01 snakeLen pic 9(4)  value 1.
01 nextSnakePos.
      10 nextSnakeRow pic 9(2).
      10 nextSnakeCol pic 9(2).

01 food.
    05 foodRow pic 9(2).
    05 foodCol pic 9(2).

01 wSize constant as 13.
01 wSizeRow constant as 13.
01 wSizeCol constant as 20.
01 game-screen.
   05 screen-row occurs wSizeRow.
      10 ScreenPixel pic x(1) occurs wSizeCol.

01 CreateFood pic X(1) value 'Y'.
01 SnakeGrew  pic X(1) value 'Y'.

01 wDummy       PIC X(01) VALUE SPACE.
01 wAnswer      pic x(01) value space.

78  K-UP          VALUE 2003.
78  K-DOWN        VALUE 2004.
78  K-LEFT        VALUE 2009.
78  K-RIGHT       VALUE 2010.
78  K-ESCAPE      VALUE 2005.

01  wCursorRowCol    PIC 9(06) value 0000.
01  redefines wCursorRowCol .
    05 wCursorRow    Pic 9(03).
    05 wCursorCol    Pic 9(03).
 01 wCRT-STATUS      PIC 9(04) VALUE 9999.
 01 wInt             binary-short signed.

 *>  mouse mask, apply to COB_MOUSE_FLAGS
78  COB-AUTO-MOUSE-HANDLING VALUE 1.
78  COB-ALLOW-LEFT-DOWN     VALUE 2.
78  COB-ALLOW-LEFT-UP       VALUE 4.
78  COB-ALLOW-LEFT-DOUBLE   VALUE 8.
78  COB-ALLOW-MIDDLE-DOWN   VALUE 16.
78  COB-ALLOW-MIDDLE-UP     VALUE 32.
78  COB-ALLOW-MIDDLE-DOUBLE VALUE 64.
78  COB-ALLOW-RIGHT-DOWN    VALUE 128.
78  COB-ALLOW-RIGHT-UP      VALUE 256.
78  COB-ALLOW-RIGHT-DOUBLE  VALUE 512.
78  COB-ALLOW-MOUSE-MOVE    VALUE 1024.
01  COB-MOUSE-FLAGS         PIC   9(04).

COPY 'GC01BOX.CPY'.
*>****************************************************************
*>
*>****************************************************************
PROCEDURE DIVISION.

  perform AcceptParameters thru AcceptParameters-Ex
  initialize game-screen replacing alphanumeric data by wFieldChar

  perform InitialSettings  thru InitialSettingsEx
  move wSnakeChar to ScreenPixel(1 1)
  move 1          to snakeCol(1) snakeRow(1)


  *> ***************************************************************
  *>  G A M E   L O O P
  *> ***************************************************************
  perform with test after until wCRT-STATUS = K-ESCAPE

      *> create food
      if CreateFood = 'Y'
            perform until ScreenPixel(foodRow, foodCol) = wFieldChar
                *> Random isn't seeded
                compute foodCol = function random * 10 + 1
                compute foodRow = function random * 10 + 1
            end-perform
            move wFoodChar to ScreenPixel(foodRow, foodCol)
            move "N"       to CreateFood
      end-if

      *> D R A W   T H E   G A M E   F I E L D
        perform varying wIndRow from 1 by 1 until wIndRow > wSizeRow
          compute wLin = wIndRow + wBaseLin
            perform varying wIndCol from 1 by 1 until wIndCol > wSizeCol
               compute wCol = wIndCol + wBaseCol
               evaluate true
                  when ScreenPixel (wIndRow, wIndCol) = wFieldChar
                       display ScreenPixel (wIndRow, wIndCol) at line wLin col wCol :BCOL: wFieldChar-bco :FCOL: wFieldChar-fco highlight
                  when ScreenPixel (wIndRow, wIndCol) = wSnakeChar
                       display ScreenPixel (wIndRow, wIndCol) at line wLin col wCol :BCOL: wSnakeChar-bco :FCOL: wSnakeChar-fco highlight blink
                  when ScreenPixel (wIndRow, wIndCol) = wFoodChar
                       display ScreenPixel (wIndRow, wIndCol) at line wLin col wCol :BCOL: wFoodChar-bco  :FCOL: wFoodChar-fco  highlight blink
               end-evaluate
            end-perform
        end-perform

        display "Score..........:"     at 0650 :BCOL: wBox-bco  :FCOL: wBox-fco highlight
        display snakeLen               at 0667 :BCOL: wBox-bco  :FCOL: wBox-fco highlight blink
        display "technical info  "     at 1250 :BCOL: wBox-bco  :FCOL: wBox-fco highlight
        display "----------------"     at 1350 :BCOL: wBox-bco  :FCOL: wBox-fco highlight
        display "game field.....:   x" at 1450 :BCOL: wBox-bco  :FCOL: wBox-fco highlight
        display  wSizeRow              at 1467 :BCOL: wBox-bco  :FCOL: wBox-fco highlight
        display  wSizeCol              at 1470 :BCOL: wBox-bco  :FCOL: wBox-fco highlight
        display "food position..:"     at 1550 :BCOL: wBox-bco  :FCOL: wBox-fco highlight
        display  food                  at 1567 :BCOL: wBox-bco  :FCOL: wBox-fco highlight
        display "nextSnakePos...:"     at 1650 :BCOL: wBox-bco  :FCOL: wBox-fco highlight
        display nextSnakePos           at 1667 :BCOL: wBox-bco  :FCOL: wBox-fco highlight
        display "snakeRow/Col(1):"     at 1750 :BCOL: wBox-bco  :FCOL: wBox-fco highlight
        display snakeRow(1)            at 1767 :BCOL: wBox-bco  :FCOL: wBox-fco highlight
        display snakeCol(1)            at 1769 :BCOL: wBox-bco  :FCOL: wBox-fco highlight


        *> A C C E P T   (WAIT) USER ACTION
        accept wDummy at 2479 with auto-skip :BCOL: wBox-bco  :FCOL: wBox-fco  end-accept

        evaluate true
            when wCRT-STATUS = K-UP    and not old-direction = DIR-DOWN
                move DIR-UP to cur-direction
            when wCRT-STATUS = K-LEFT  and not old-direction = DIR-RIGHT
                move DIR-LEFT to cur-direction
            when wCRT-STATUS = K-DOWN  and not old-direction = DIR-UP
                move DIR-DOWN to cur-direction
            when wCRT-STATUS = K-RIGHT and not old-direction = DIR-LEFT
                move DIR-RIGHT to cur-direction
            when other
                exit perform cycle *> --> wait for other user action
        end-evaluate

        *> get-next-pos
        move snakeCol(1) to nextSnakeCol
        move snakeRow(1) to nextSnakeRow
        evaluate true
            when cur-direction = DIR-UP
                if snakeRow(1) = 1 move wSizeRow to nextSnakeRow
                else               subtract 1 from snakeRow(1) giving nextSnakeRow end-if
            when cur-direction = DIR-LEFT
                if snakeCol(1) = 1 move wSizeCol to nextSnakeCol
                else               subtract 1 from snakeCol(1) giving nextSnakeCol end-if
            when cur-direction = DIR-DOWN
                if snakeRow(1) = wSizeRow move 1 to nextSnakeRow
                else                      add  1 to snakeRow(1) giving nextSnakeRow end-if
            when cur-direction = DIR-RIGHT
                if snakeCol(1) = wSizeCol move 1 to nextSnakeCol
                else                      add  1 to snakeCol(1) giving nextSnakeCol end-if
        end-evaluate

        move 'N' to SnakeGrew
        if ScreenPixel(nextSnakeRow, nextSnakeCol) = wSnakeChar
            *> snake on snake itself = game over
            exit perform
        else
            *> snake on food
            if nextSnakeCol = foodCol and nextSnakeRow = foodRow
                add 1 to snakeLen
                compute snakeCol(snakeLen) = snakeCol(snakeLen - 1)
                compute snakeRow(snakeLen) = snakeRow(snakeLen - 1)
                move 'Y' to CreateFood SnakeGrew
                *> display wDummy at 1020 with beep
                *> CALL X"E5" *> sounds a BEEP !
            end-if
        end-if
        move wSnakeChar to ScreenPixel(nextSnakeRow, nextSnakeCol)
        if SnakeGrew = 'N'
            move wFieldChar to ScreenPixel(snakeRow(snakeLen), snakeCol(snakeLen))
        end-if

        *> shift (move) snake
        perform varying snakeIdx from snakeLen by -1 until snakeIdx = 1
            compute snakeCol(snakeIdx) = snakeCol(snakeIdx - 1)
            compute snakeRow(snakeIdx) = snakeRow(snakeIdx - 1)
        end-perform
        move nextSnakeCol to snakeCol(1)
        move nextSnakeRow to snakeRow(1)
        move cur-direction to old-direction

  end-perform
  *> ***************************************************************
  *>  E N D   O F   G A M E   L O O P
  *> ***************************************************************


  display " GAME OVER! Score: " at 0230
  display snakeLen              at 0249 accept omitted
    display ' ' at 0101 with blank screen *> clear screen
    display ' ' at 2101
  stop run.
*>****************************************************************
*> END OF PROGRAM
*>****************************************************************


AcceptParameters.
  display '  '
  display 'GnuCOBOL SNAKE GAME '
  display 'Field character (default is ".") .................: ' with no advancing
  accept wFieldChar
  if wFieldChar  = space move "." to wFieldChar  end-if
  display 'Snake character (default is "o") .................: ' with no advancing
  accept wSnakeChar
  if wSnakeChar = space move "o" to wSnakeChar end-if
  display 'Food  character (default is "#") .................: ' with no advancing
  accept wFoodChar
  if wFoodChar  = space move "#" to wFoodChar  end-if

  display space
  display '----------------------------------------  '
  display 'Field character ........................: ' wFieldChar
  display 'Snake character ........................: ' wSnakeChar
  display 'Food  character ........................: ' wFoodChar
  display 'Continue (Y/N or R=Repeat) ? ...........: ' with no advancing
  accept  wAnswer

  if wAnswer = 'R' or 'r'
      display ' '
      display '... repeating ...'
      move space to wSnakeChar wFoodChar
      go to AcceptParameters
  end-if

  if wAnswer = 'Y' or 'y' or space
     continue
  else
      display space
      display '... Processing ended by the user !' with no advancing
      display space
      goback
  end-if.
AcceptParameters-Ex. exit.

InitialSettings.
  *> sets in order to detect the PgUp, PgDn, PrtSc(screen print), Esc keys,
  set environment 'COB_SCREEN_EXCEPTIONS' TO 'Y'.
  set environment 'COB_SCREEN_ESC'        TO 'Y'.

  *> clear screen and initialize pdcurses library
  display ' ' at 0101 with blank screen
  *> hide the cursor
  move 0 to wInt;  call static "curs_set" using by value wInt end-call
  *> make mouse active
  COMPUTE COB-MOUSE-FLAGS   = COB-AUTO-MOUSE-HANDLING
    + COB-ALLOW-LEFT-DOWN   + COB-ALLOW-MIDDLE-DOWN   + COB-ALLOW-RIGHT-DOWN
    + COB-ALLOW-LEFT-UP     + COB-ALLOW-MIDDLE-UP     + COB-ALLOW-RIGHT-UP
    + COB-ALLOW-LEFT-DOUBLE + COB-ALLOW-MIDDLE-DOUBLE + COB-ALLOW-RIGHT-DOUBLE
    + COB-ALLOW-MOUSE-MOVE
  SET environment "COB_MOUSE_FLAGS" to COB-MOUSE-FLAGS

  *> BIG BOX as BACKGROUD
  move wBox-bco to Box-bco
  move wBox-fco to Box-fco
  move 'S'   to Box-style
  move 'N'   to Box-Shadow
  move '001001025080' to Box-rc
  call GC01BOX using BOX-AREA
       on exception display "program GC01BOX not found, enter to continue without boxes ..." accept omitted end-call

  display ' GnuCOBOL SNAKE GAME V.1.1 '  at 002002 :BCOL: red :FCOL: yellow highlight end-display
  display " use cursor keys to move the snake, ESC to exit."   at 023002 :BCOL: red :FCOL: yellow highlight end-display

  move wFieldChar-bco to Box-bco
  move wFieldChar-fco to Box-fco
  move 'S'   to Box-style
  move 'N'   to Box-Shadow
  compute Box-r1 = wBaseLin
  compute Box-c1 = wBaseCol
  compute Box-r2 = wBaseLin + wSizeRow + 1
  compute Box-c2 = wBaseCol + wSizeCol + 1
  call GC01BOX using BOX-AREA
       on exception display "program GC01BOX not found, enter to continue without boxes ..." accept omitted end-call
  continue.

InitialSettingsEx. exit.

End program GC99SNAKE.


       get-next-pos-left.
           if snake-x(1) = 1 then
                 move 10 to next-snake-x
           else
                 subtract 1 from snake-x(1) giving next-snake-x
           end-if.

       get-next-pos-down.
           if snake-y(1) = 10 then
                 move 1 to next-snake-y
           else
                 add 1 to snake-y(1) giving next-snake-y
           end-if.

       get-next-pos-right.
           if snake-x(1) = 10 then
                 move 1 to next-snake-x
           else
                 add 1 to snake-x(1) giving next-snake-x
           end-if.
