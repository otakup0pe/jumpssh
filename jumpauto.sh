#!/usr/bin/env bash

function usage
{
    echo "jumpauto [start|stop|status]"
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

. "${JUMPSSH_SOCKS}"

if [ ! -d "$PIDDIR" ] ; then
    mkdir -p "$PIDDIR"
fi
if [ ! -d "$LOGDIR" ] ; then
    mkdir -p "$LOGDIR"
fi

problems()
{
    echo "Error ${1}"
    exit 1
}

start_jump()
{
    HOST="${1}"
    AUTOSSH_PIDFILE="${PIDDIR}/${HOST}"
    if [ -e "$AUTOSSH_PIDFILE" ] ; then
        
        if ps "$(cat "$AUTOSSH_PIDFILE")" &> /dev/null ; then
            echo "${HOST} already running"
        else
            echo "${HOST} crashed"
        fi
    fi
    AUTOSSH_PIDFILE=$AUTOSSH_PIDFILE \
                   AUTOSSH_LOGFILE="${LOGDIR}/autossh-${HOST}" \
                   AUTOSSH_POLL=5 \
                   autossh -f -M $RANDOM "$HOST" -N
    unset AUTOSSH_PIDFILE
    unset HOST
}

stop_jump()
{
    HOST="${1}"
    AUTOSSH_PIDFILE="${PIDDIR}/${HOST}"
    if [ ! -e "$AUTOSSH_PIDFILE" ] ; then
        echo "${HOST} not running"
    else
        kill "$(cat "$AUTOSSH_PIDFILE")"
    fi
    unset AUTOSSH_PIDFILE
    unset HOST
}

function status_jump
{
    HOST="${1}"
    AUTOSSH_PIDFILE="${PIDDIR}/${HOST}"
    if [ ! -e "$AUTOSSH_PIDFILE" ] ; then
        echo "${HOST} not running"
    else
        
        if ps "$(cat "$AUTOSSH_PIDFILE")" &> /dev/null ; then
            echo "${HOST} is running"
        else
            echo "${HOST} crashed"
        fi
    fi
}

case "${CMD}" in
    start)
        if [ "$JUMP" == "" ] ; then
            for j in $JUMPSSH_AUTO ; do
                start_jump "$j" || problems "unable to start ${j}"
            done
        else
            start_jump "$JUMP"
        fi
        ;;
    stop)
        if [ "$JUMP" == "" ] ; then
            for j in $JUMPSSH_AUTO ; do
                stop_jump "$j" || problems "unable to stop ${j}"
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
    *)
        usage
        ;;
esac
unset JUMP
