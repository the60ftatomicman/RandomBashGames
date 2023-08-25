
KEY_UP="w"
KEY_DOWN="s"
KEY_LEFT="a"
KEY_RIGHT="d"
KEY_SELECT="j"
KEY_RESET="r"
KEY_QUIT="q"
SYMBOL_PEG="0"
SYMBOL_HOLE="O"
SYMBOL_EDGE="▓"
SYMBOL_LINE="/"
SYMBOL_BOARD=" "

ROW=2
COL=6
CURR_SELECTION=-2

BOARD_ROW_MAX=5
BOARD_COL_MAX=13
BOARD=(
    0 0 0 0 5 4 1 4 3 0 0 0 0
    0 0 0 5 4 1 4 1 4 3 0 0 0
    0 0 5 4 1 4 1 4 1 4 3 0 0
    0 5 4 1 4 1 4 1 4 1 4 3 0
    5 4 1 4 1 4 1 4 1 4 1 4 3
)
BOARD_TEXT=""

function makeSelection() {
    if [ "$1" = "$KEY_SELECT" ]; then
        CURRENT_CELL=$((($ROW*$BOARD_COL_MAX)+$COL))
        CHAR=${BOARD[$CURRENT_CELL]}
        # We picked a cell
        if [ "$CHAR" = "1" ];then
            if [ "$CURR_SELECTION" = "$CURRENT_CELL" ];then
                CURR_SELECTION=-1
            else
                CURR_SELECTION=$CURRENT_CELL
            fi

        fi
        #Attempting a JUMP
        if [ "$CHAR" = "2" ];then
            if [ "$CURR_SELECTION" -ge 0 ]; then
                ROW_A=$(($CURR_SELECTION / $BOARD_COL_MAX))
                ROW_B=$(($CURRENT_CELL / $BOARD_COL_MAX))
                ROW_DIF=$(($ROW_A-$ROW_B))
                ROW_OK=false
                if [[ $ROW_A -eq $ROW_B || "${ROW_DIF#-}" = "2" ]]; then
                    ROW_OK=true
                fi
                COL_A=$(($CURR_SELECTION % $BOARD_COL_MAX))
                COL_B=$(($CURRENT_CELL % $BOARD_COL_MAX))
                COL_DIF=$(($COL_A - $COL_B))
                COL_OK=false
                NEEDED_COL_DIF=2
                if [ $ROW_DIF -eq 0 ]; then
                    NEEDED_COL_DIF=4
                fi
                if [ "${COL_DIF#-}" = "$NEEDED_COL_DIF" ]; then
                    COL_OK=true
                fi
                #echo "A: RC[${ROW_A},${COL_A}] B: RC[${ROW_B},${COL_B}] OK: RC[${ROW_OK},${COL_OK}]"
                if [[ "$ROW_OK" = true && "$COL_OK" = true ]];then
                    performJump $ROW_A $COL_A $ROW_B $COL_B
                    CURR_SELECTION=-1
                fi
            fi
        fi
    fi
}
function performJump() {
    ROW_DIF=$(($1-$3))
    TARGET_ROW=$1
    if [ $ROW_DIF -ne 0 ]; then
        TARGET_ROW=$(($TARGET_ROW+(($ROW_DIF / 2)*-1)))
    fi

    COL_DIF=$(($2-$4))
    TARGET_COL=$(($2+(($COL_DIF / 2)*-1)))

    TARGET_IDX=$((($TARGET_ROW*$BOARD_COL_MAX)+$TARGET_COL))
    #echo "JUMPING ${TARGET_ROW},${TARGET_COL} or ${TARGET_IDX}"

    #Jump Peg
    BOARD[$TARGET_IDX]=2
    #Hole at start
    TARGET_IDX=$((($1*$BOARD_COL_MAX)+$2))
    BOARD[$TARGET_IDX]=2
    #Peg at end
    TARGET_IDX=$((($3*$BOARD_COL_MAX)+$4))
    BOARD[$TARGET_IDX]=1
}

function moveSelection() {
        COLDIR=0
        #Handle Movement
        if [ "$1" = "$KEY_LEFT" ]; then
            COLDIR=-1
        fi
        if [ "$1" = "$KEY_RIGHT" ]; then
            COLDIR=1
        fi
        if [ "$1" = "$KEY_UP" ]; then
            ROW=$(($ROW-1))
            if [ $COL -le $((($BOARD_COL_MAX/2) - 1)) ]; then
                COLDIR=1
            else
                COLDIR=-1
            fi
        fi
        if [ "$1" = "$KEY_DOWN" ]; then
            ROW=$(($ROW+1))
            if [ $COL -le $((($BOARD_COL_MAX/2) - 1)) ]; then
                COLDIR=1
            else
                COLDIR=-1
            fi
        fi
        if [ $ROW -lt 0 ]; then
            ROW=$(($BOARD_ROW_MAX-1))
        fi
        if [ $ROW -ge $BOARD_ROW_MAX ]; then
            ROW=0
        fi
        if [ $COLDIR != 0 ]; then
            CHAR="0"
            while [[ "$CHAR" != "1" && "$CHAR" != "2" ]]
            do
                COL=$(($COL+$COLDIR))
                if [ $COL -ge $BOARD_COL_MAX ]; then
                    COL=0
                else
                    if [ $COL -lt 0 ]; then
                        COL=$(($BOARD_COL_MAX-1))
                    fi
                fi

                ##
                CURRENT_CELL=$((($ROW*$BOARD_COL_MAX)+$COL))
                CHAR=${BOARD[$CURRENT_CELL]}
            done
        fi
}

#https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
function printBoard {
    BOARD_TEXT=""
    CELL_IDX=0
    CURRENT_CELL=$((($ROW*$BOARD_COL_MAX)+$COL))
    #echo "Current Cell: ${CURRENT_CELL}"
    for r in {0..4}
    do
        for c in {0..12}
        do
            #SET MY COLOR
            FG="97"
            BG="40"
            if [ "$CURRENT_CELL" = "$CELL_IDX" ]; then
                BG="47"
            fi
            CHAR_NUM=${BOARD[$CELL_IDX]}
            CHAR=" "
            if [ "$CHAR_NUM" = "1" ]; then
                CHAR=$SYMBOL_PEG
                FG="97"
                if [ "$CURR_SELECTION" = "$CELL_IDX" ]; then
                    FG="96"
                fi
            elif [ "$CHAR_NUM" = "2" ]; then
                CHAR=$SYMBOL_HOLE
                FG="90"
            elif [ "$CHAR_NUM" = "3" ]; then
                CHAR=$SYMBOL_EDGE
                BG="100"
            elif [ "$CHAR_NUM" = "4" ]; then
                CHAR=$SYMBOL_BOARD
                BG="100"
            elif [ "$CHAR_NUM" = "5" ]; then
                CHAR=$SYMBOL_LINE
            else
                CHAR=" "
            fi
            PRE="\e[${FG};${BG}m"
            BOARD_TEXT="${BOARD_TEXT}${PRE}${CHAR}\e[0m"
            CELL_IDX=$(($CELL_IDX+1))
        done
        if [ "$r" != "4" ]; then
            BOARD_TEXT="${BOARD_TEXT}\n"
        fi
    done

    if [[ "$CURR_SELECTION" = "-2" ]]; then
        echo "Pick a starting hole!"
    fi
    echo -e "     ${SYMBOL_LINE}\e[97;100m ${SYMBOL_EDGE}\e[0m    "
    echo -e "${BOARD_TEXT}"
    echo -e "-------------"
    echo "[wasd] moves. [j] is action. [q] quits. [r] restarts."
}
function readEscape {

    IFS= read -s -n1 input
    clear
    #if [ "$input" = $'\E' ]; then
    #    read -s -n2 input
        #echo "control key pressed: $input"
    #else
        #echo "standard key pressed: $input"

    #fi

    if [ "$input" = "$KEY_QUIT" ]; then
        clear
        echo "Exit"
    else
        if [ "$input" = "$KEY_RESET" ]; then
            BOARD=(
                0 0 0 0 5 4 1 4 3 0 0 0 0
                0 0 0 5 4 1 4 1 4 3 0 0 0
                0 0 5 4 1 4 1 4 1 4 3 0 0
                0 5 4 1 4 1 4 1 4 1 4 3 0
                5 4 1 4 1 4 1 4 1 4 1 4 3
            )
            BOARD_TEXT=""
            ROW=2
            COL=6
            CURR_SELECTION=-2
        else
            moveSelection "$input"
            if [[ "$CURR_SELECTION" = "-2" && "$input" = "$KEY_SELECT" ]];then
                CURRENT_CELL=$((($ROW*$BOARD_COL_MAX)+$COL))
                CURR_SELECTION=$CURRENT_CELL
                BOARD[$CURR_SELECTION]=2
            else
                makeSelection "$input"
            fi
            echo "Row: $ROW Col: $COL Selected: $CURR_SELECTION"
        fi
        printBoard
        readEscape
    fi
}

clear
printBoard
readEscape