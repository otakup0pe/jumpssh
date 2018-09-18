
. "${JUMPSSH_SOCKS}"

alias jumpauto="${JUMPSSH_PATH}/jumpauto.sh"

function jumpssh {
    if [ $# -lt 2 ] ; then
        echo "jumpssh [jump shortname] ssh args"
    else
        JUMP=$(echo $1 | sed -e 's!-!!')
        shift
        JUNK=$*
        VARNAME="${JUMP}_PORT"
        PORT="${!VARNAME}"
        if [ "$PORT" == "" ] ; then
            echo "invalid jump shortname"
        else
            ssh -o ProxyCommand="nc -x localhost:$PORT %h %p" $JUNK
        fi
    fi
}

function jumpscp {
    if [ $# -lt 2 ] ; then
        echo "jumpscp [jump shortname] scp args"
    else
        JUMP=$(echo $1 | sed -e 's!-!!')
        shift
        JUNK=$*
        VARNAME="${JUMP}_PORT"
        PORT="${!VARNAME}"
        if [ "$PORT" == "" ] ; then
            echo "invalid jump shortname"
        else
            scp -o ProxyCommand="nc -x localhost:$PORT %h %p" $JUNK
        fi
    fi
}

function jumpcurl {
    if [ $# -lt 2 ] ; then
        echo "jumpcurl [jump shortname] curl args"
    else
        JUMP=$(echo $1 | sed -e 's!-!!')
        shift
        JUNK=$*
        VARNAME="${JUMP}_PORT"
        PORT="${!VARNAME}"
        if [ "$PORT" == "" ] ; then
            echo "invalid jump shortname"
        else
            curl --proxy socks5h://127.0.0.1:$PORT $JUNK
        fi
    fi
}

function jump_prompt {
    NAME=$1
    PORT=$2
    if [ "$OS" == "Darwin" ] ; then
        P_SOCKS="$(netstat -na | grep tcp4 | grep -e "\.$PORT" | wc -l | sed -e 's! !!g')"
    elif [ "$OS" == "Cygwin" ] ; then
        P_SOCKS="$(netstat -na | grep TCP | grep -e ":$PORT" | wc -l | sed -e 's! !!g')"
    elif [ "$OS" == "WSL" ] ; then
        P_SOCKS="$(netstat.exe -na | grep TCP | grep -e "$PORT" | wc -l | sed -e 's! !!g')"
    else
        P_SOCKS="$(netstat -na | grep tcp4 | grep -e ":$PORT" | wc -l | sed -e 's! !!g')"
    fi
    if [ "$P_SOCKS" == "0" ] ; then
        C=$RED
        S=""
    else
        C=$GREEN
        S="${BLACKBOLD} ${P_SOCKS}"
    fi
    if [ "${P_SOCKS}" != "" ] ; then
        P_SOCKS=":${P_SOCKS}"
    fi
    echo "${C}${NAME}${OFF}${P_SOCKS}"
}
