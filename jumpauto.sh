#!/usr/bin/env bash

set -e

function usage
{
    echo "jumpauto [start|stop|restart|status]"
    exit 1
}

if [ $# == 1 ] ; then
    CMD="$1"
    JUMP=""
elif [ $# == 2 ] ; then
    CMD="$2"
    JUMP="$1"
else
    usage
fi

LOGDIR="${HOME}/var/log"
if [ -z "${JUMPSSH_TMP}" ] ; then
    PIDDIR="${JUMPSSH_PATH}/tmp"
else
    PIDDIR=$JUMPSSH_TMP
fi

if [ -z "$JUMPSSH_SOCKS" ] ; then
    problems "Must define JUMPSSH_SOCKS file"
fi

if [ ! -e "$JUMPSSH_SOCKS" ] ; then
    problems "Config file ${JUMPSSH_SOCKS} not found"
fi

# shellcheck disable=SC1090
. "${JUMPSSH_SOCKS}"

if [ ! -d "$PIDDIR" ] ; then
    mkdir -p "$PIDDIR"
fi
if [ ! -d "$LOGDIR" ] ; then
    mkdir -p "$LOGDIR"
fi

warn()
{
    >&2 echo "$1"
}

problems()
{
    >&2 echo "Error $1"
    exit 1
}

check_pid()
{
    local HOST="$1"
    AUTOSSH_PIDFILE="${PIDDIR}/${HOST}"
    [ -n "$AUTOSSH_PIDFILE" ]
    if [ -e "$AUTOSSH_PIDFILE" ] ; then
        JUMPSSH_PID="$(cat "$AUTOSSH_PIDFILE")"
        if [ -n "$JUMPSSH_PID" ] && ps "$JUMPSSH_PID" &> /dev/null  ; then
            return
        fi
        JUMPSSH_PID=""
    fi
    if [ -z "$JUMPSSH_PID" ] ; then
        JUMPSSH_PID="$(pgrep -f ".+autossh.+${HOST} -N" || true)"
        if [ -n "$JUMPSSH_PID" ] ; then
            echo "$JUMPSSH_PID" > "$AUTOSSH_PIDFILE"
        fi
    fi
    if [ -n "$JUMPSSH_PID" ] ; then
        if [ -e "$AUTOSSH_PIDFILE" ] ; then
            rm "$AUTOSSH_PIDFILE"
        fi
    fi
}

start_jump()
{
    local HOST="${1}"
    check_pid "$HOST"
    if [ -n "$JUMPSSH_PID" ] ; then
        warn "${HOST} already running"
        return
    fi
    M_PORT="$(((RANDOM % 1000) + 40000))"
    AUTOSSH_PIDFILE=$AUTOSSH_PIDFILE \
                   AUTOSSH_LOGFILE="${LOGDIR}/autossh-${HOST}" \
                   AUTOSSH_POLL=5 \
                   autossh -f -M "$M_PORT" "$HOST" -N
    unset AUTOSSH_PIDFILE
}

stop_jump()
{
    local HOST="${1}"
    check_pid "$HOST"
    if [ -z "$JUMPSSH_PID" ] ; then
        warn "${HOST} not running"
        return
    fi
    kill "$(cat "$AUTOSSH_PIDFILE")"
    unset AUTOSSH_PIDFILE
}

function status_jump
{
    local HOST="${1}"
    check_pid "$HOST"
    if [ -z "$JUMPSSH_PID" ] ;then
        echo "${HOST} not running"
    else
        echo "${HOST} is running"
    fi
}

case "${CMD}" in
    start)
        if [ "$JUMP" == "" ] ; then
            for j in $JUMPSSH_AUTO ; do
                start_jump "$j"
            done
        else
            start_jump "$JUMP"
        fi
        ;;
    stop)
        if [ "$JUMP" == "" ] ; then
            for j in $JUMPSSH_AUTO ; do
                stop_jump "$j"
            done
        else
            stop_jump "$JUMP"
        fi
        ;;
    status)
        if [ "$JUMP" == "" ] ; then
            for j in $JUMPSSH_AUTO ; do
                status_jump "$j"
            done
        else
            status_jump "$JUMP"
        fi
        ;;
    restart)
        "$0" stop
        "$0" start
        ;;
    *)
        usage
        ;;
esac
unset JUMP
