SYMBOL_FACE_LAND="░"
SYMBOL_FACE_OFF="▓"
SYMBOL_FACE_ON="▓"
SYMBOL_QBERT="Q"
SYMBOL_TELEPORT="_"
SYMBOL_ENEMY="S"

KEY_UP="w"
KEY_DOWN="s"
KEY_LEFT="a"
KEY_RIGHT="d"
KEY_QUIT="q"

ROW=1
COL=8
CURRENT_CELL=9
ENEMY_COORDS=(
    4 9 1
    -1 -1 10
    -1 -1 15
)

STATE_TITLE=0
STATE_PLAYING=1
STATE_DEAD=2
STATE_WON=3
STATE=$STATE_PLAYING

BOARD_ROW_MAX=8
BOARD_COL_MAX=16
BOARD_CELLS=$(($BOARD_ROW_MAX*$BOARD_COL_MAX))
BOARD=(
    0 0 0 0 0 0 0 0 1 3 0 0 0 0 0 0
    0 0 0 0 0 0 0 1 3 1 3 0 0 0 0 0
    0 0 0 0 0 0 1 3 1 3 1 3 0 0 0 0
    0 0 0 0 0 1 3 1 3 1 3 1 3 0 0 0
    0 0 0 5 1 3 1 3 1 3 1 3 1 3 0 5
    0 0 0 1 3 1 3 1 3 1 3 1 3 1 3 0
    0 0 1 3 1 3 1 3 1 3 1 3 1 3 1 3
)
BOARD_TEXT=""

function writeKeys {
    printf %s "$ROW,$COL" > ./input.qbert
}
function readKeys {
    #read file
    coords=$(cat ./input.qbert)
    #echo $coords
    #split into array
    IFS=','
    read -a rc <<< "$coords"
    #echo "R:${rc[0]} C:${rc[1]}"
    ROW="${rc[0]}"
    COL="${rc[1]}"
    CURRENT_CELL=$((($ROW*$BOARD_COL_MAX)+$COL))
    #echo "R:${ROW} C:${COL}"
}
#Up=up-right, Down=down-left, Left=up-left, and Right=down-right
function waitKeys {
    IFS= read -s -n1 input
    DIR_X=0
    DIR_Y=0
    
    if [ "$input" = "$KEY_UP" ]; then
        DIR_Y=-1
        DIR_X=1
    elif [ "$input" = "$KEY_DOWN" ]; then
        DIR_Y=1
        DIR_X=-1
    elif [ "$input" = "$KEY_LEFT" ]; then
        DIR_Y=-1
        DIR_X=-1
    elif [ "$input" = "$KEY_RIGHT" ]; then
        DIR_Y=1
        DIR_X=1
    elif [ "$input" = "$KEY_QUIT" ]; then
        pkill -P $$
        clear
        exit
    fi
    readKeys
    ROW=$(($ROW+$DIR_Y))
    COL=$(($COL+$DIR_X))
}
function interpretState {
    CHAR=${BOARD[$CURRENT_CELL]}
    # Are we dead or teleporting
    if [[ "$CHAR" = "" ||  "$CHAR" = "0" ]];then
        STATE=$STATE_DEAD
    elif [ "$CHAR" = "5"  ]; then
        BOARD[$CURRENT_CELL]=0
        ROW=0
        COL=9
        writeKeys
    fi
    # Did I hit an enemy?
    i=0
    j=1
    while [ $i -lt ${#ENEMY_COORDS[*]} ]; do
        if [[ "$ROW" = "${ENEMY_COORDS[$i]}" && "$COL" = "${ENEMY_COORDS[$j]}" ]];then
            STATE=$STATE_DEAD
        fi
        i=$(( $i + 2));
        j=$(( $j + 2));
    done
    # Did we land on a normal tile?
    if [[ "$CHAR" = "3" ]]; then
        BOARD[$CURRENT_CELL]=2
    fi
    # Have we won?
    CLEANCELLS=0
    for cell in "${BOARD[@]}"
    do
        if [ "$cell" = "3" ];then
            CLEANCELLS=$(($CLEANCELLS+1))
        fi
    done
    if [ "$CLEANCELLS" = "0" ];then
        STATE=$STATE_WON
    fi
}
function moveEnemies {
    i=0
    j=1
    k=2
    while [ $i -lt ${#ENEMY_COORDS[*]} ]; do
        RANDOM_DIR=$(( $RANDOM % 5 + 1 ))
        curry=${ENEMY_COORDS[$i]}
        currx=${ENEMY_COORDS[$j]}
        moveTimer=${ENEMY_COORDS[$k]}
        if [ $moveTimer -gt 0 ]; then
            ENEMY_COORDS[$k]=$(($moveTimer-1))
        else
            ENEMY_COORDS[$k]=$(( $RANDOM % 3 + 1 ))
            if [[ "$curry" == -1 && "$currx" == -1 ]];then
                if [[ "$RANDOM_DIR" = "1"  || "$RANDOM_DIR" = "2" ]];then
                    ENEMY_COORDS[$i]=0
                    ENEMY_COORDS[$j]=9
                fi
            else
                if [ "$RANDOM_DIR" = "1" ];then
                    ENEMY_COORDS[$i]=$(($curry+1))
                    ENEMY_COORDS[$j]=$(($currx+1))
                elif [ "$RANDOM_DIR" = "2" ];then
                    ENEMY_COORDS[$i]=$(($curry+1))
                    ENEMY_COORDS[$j]=$(($currx-1))
                elif [ "$RANDOM_DIR" = "3" ];then
                    ENEMY_COORDS[$i]=$(($curry-1))
                    ENEMY_COORDS[$j]=$(($currx+1))
                elif [ "$RANDOM_DIR" = "4" ];then
                    ENEMY_COORDS[$i]=$(($curry-1))
                    ENEMY_COORDS[$j]=$(($currx-1))
                else
                    ENEMY_COORDS[$i]=$curry
                    ENEMY_COORDS[$j]=$currx
                fi
                # Test if in hole
                CC_E=$((($ROW*$BOARD_COL_MAX)+$COL))
                CHAR=${BOARD[$CC_E]}
                # Are we dead or teleporting
                if [[ "$CHAR" = "" ||  "$CHAR" = "0" ]];then
                    ENEMY_COORDS[$i]=-1
                    ENEMY_COORDS[$j]=-1
                    ENEMY_COORDS[$k]=5
                fi
            fi
        fi

        i=$(( $i + 3));
        j=$(( $j + 3));
        k=$(( $k + 3));
    done 
}
function draw {
    BOARD_TEXT=""
    CELL_IDX=0
    for r in {0..6}
    do
        for c in {0..15}
        do
            #Try to see if an enemy is here
            CHAR=" "
            i=0
            j=1
            while [ $i -lt ${#ENEMY_COORDS[*]} ] && [ "$CHAR" = " " ]; do
                if [[ "$r" = "${ENEMY_COORDS[$i]}" && "$c" = "${ENEMY_COORDS[$j]}" ]];then
                    CHAR="$SYMBOL_ENEMY"
                fi
                i=$(( $i + 2));
                j=$(( $j + 2));
            done
            #Test if its the hero spot
            if [ "$CHAR" = "$SYMBOL_ENEMY" ];then
                FG="35"
                BG="40"
            elif [ "$CELL_IDX" = "$CURRENT_CELL" ];then
                FG="31"
                BG="40"
                CHAR=$SYMBOL_QBERT
            else
                #SET MY COLOR
                FG="97"
                BG="40"
                CHAR_NUM=${BOARD[$CELL_IDX]}
                if [ "$CHAR_NUM" = "1" ]; then
                    CHAR=$SYMBOL_FACE_LAND
                elif [ "$CHAR_NUM" = "2" ]; then
                    FG="32"
                    CHAR=$SYMBOL_FACE_ON
                elif [ "$CHAR_NUM" = "3" ]; then
                    CHAR=$SYMBOL_FACE_OFF
                elif [ "$CHAR_NUM" = "4" ]; then
                    CHAR=$SYMBOL_LINE_UP
                elif [ "$CHAR_NUM" = "5" ]; then
                    CHAR=$SYMBOL_TELEPORT
                else
                    CHAR=" "
                fi
            fi
            PRE="\e[${FG};${BG}m"
            BOARD_TEXT="${BOARD_TEXT}${PRE}${CHAR}\e[0m"
            #BOARD_TEXT="${BOARD_TEXT}${CHAR}\e[0m"
            CELL_IDX=$(($CELL_IDX+1))
        done
        BOARD_TEXT="${BOARD_TEXT}\n"

    done
    echo -e "${BOARD_TEXT}"
    echo "[wasd] moves. [q] quits."
    #[$ROW][$COL][${CURRENT_CELL}]
}
function gameloop {
    clear
    interpretState
    moveEnemies
    readKeys
    if [ "$STATE" = "$STATE_PLAYING" ]; then
        draw
    elif [ "$STATE" = "$STATE_DEAD" ]; then
        echo -e "\n\n\n     WOMP WOMP YA DEAD     \n\n\n\n"
    elif [ "$STATE" = "$STATE_WON" ]; then
        echo -e "\n\n\n     Ya DID IT     \n\n\n\n"
    else
        echo -e "STATE ERROR -- ${STATE}"
    fi
    sleep $((1/1))
    gameloop
}
#SETUP
writeKeys
#RENDER
gameloop &
#INPUT
while true
do
    waitKeys
    writeKeys
#    sleep $((1/1))
done
