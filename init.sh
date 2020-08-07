
# -*-Shell-script-*-
# shellcheck shell=bash
if [ -z "$JUMPSSH_SOCKS" ] ; then
    >&2 echo "JUMPSSH_SOCKS not found, behavior undefined"
fi

if [ ! -e "$JUMPSSH_SOCKS" ] ; then
    >&2 echo "Config file ${JUMPSSH_SOCKS} not found, behavior undefined"
fi

# shellcheck disable=SC1090
. "${JUMPSSH_SOCKS}"

alias jumpauto='${JUMPSSH_PATH}/jumpauto.sh'

function jumpssh {
    if [ $# -lt 2 ] ; then
        echo "jumpssh [jump shortname] ssh args"
    else
        JUMP="${1//-/}"
        shift
        VARNAME="${JUMP}_PORT"
        PORT="${!VARNAME}"
        if [ "$PORT" == "" ] ; then
            echo "invalid jump shortname"
        else
            # shellcheck disable=SC2029,SC2086
            ssh -o ProxyCommand="nc -x localhost:$PORT %h %p" "$@"
        fi
    fi
}

function jumpscp {
    if [ $# -lt 2 ] ; then
        echo "jumpscp [jump shortname] scp args"
    else
        JUMP="${1//-/}"
        shift
        VARNAME="${JUMP}_PORT"
        PORT="${!VARNAME}"
        if [ "$PORT" == "" ] ; then
            echo "invalid jump shortname"
        else
            scp -o ProxyCommand="nc -x localhost:$PORT %h %p" "$@"
        fi
    fi
}

function jumpcurl {
    if [ $# -lt 2 ] ; then
        echo "jumpcurl [jump shortname] curl args"
    else
        JUMP="${1//-/}"
        shift
        VARNAME="${JUMP}_PORT"
        PORT="${!VARNAME}"
        if [ "$PORT" == "" ] ; then
            echo "invalid jump shortname"
        else
            curl --proxy "socks5h://127.0.0.1:${PORT}" "$@"
        fi
    fi
}

function jump_prompt {
    NAME=$1
    PORT=$2
    if [ "$OS" == "Darwin" ] ; then
        P_SOCKS="$(netstat -na | grep tcp4 | grep -ce "\.$PORT")"
    elif [ "$OS" == "Cygwin" ] ; then
        P_SOCKS="$(netstat -na | grep TCP | grep -ce ":$PORT")"
    elif [ "$OS" == "WSL" ] ; then
        if command -v netstat.exe &> /dev/null ; then
            P_SOCKS="$(netstat.exe -na | grep TCP | grep -c "$PORT")"
        elif [ -e /c/Windows/System32/NETSTAT.EXE ] ; then
            P_SOCKS="$( /c/Windows/System32/NETSTAT.EXE -na | grep TCP | grep -c "$PORT")"
        else
            P_SOCKS=""
        fi
    else
        P_SOCKS="$(netstat -na | grep tcp4 | grep -ce ":$PORT")"
    fi
    if [ "$P_SOCKS" == "0" ] ; then
        C=$RED
    else
        C=$GREEN
    fi
    if [ "${P_SOCKS}" != "" ] ; then
        P_SOCKS=":${P_SOCKS}"
    fi
    echo "${C}${NAME}${OFF}${P_SOCKS}"
}
