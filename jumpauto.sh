#!/usr/bin/env bash

function usage
{
    echo "jumpauto [start|stop|status]"
    exit 1
}

if [ $# == 1 ] ; then
    JUMP=""
elif [ $# == 2 ] ; then
    JUMP=$2
else
    usage
fi

CMD="${1}"

if [ "${JUMPSSH_TMP}" == "" ] ; then
    PIDDIR="${JUMPSSH_PATH}/tmp"
else
    PIDDIR=$JUMPSSH_TMP
fi

. "${JUMPSSH_SOCKS}"

if [ ! -d $PIDDIR ] ; then
    mkdir -p $PIDDIR
fi

function problems
{
    echo "Error ${1}"
    exit 1
}

function start_jump
{
    HOST="${1}"
    AUTOSSH_PIDFILE="${PIDDIR}/${HOST}"
    if [ -e $AUTOSSH_PIDFILE ] ; then
        ps $(cat $AUTOSSH_PIDFILE) &> /dev/null
        if [ $? == 0 ] ; then
            echo "${HOST} already running"
        else
            echo "${HOST} crashed"
        fi
    fi
    AUTOSSH_PIDFILE=$AUTOSSH_PIDFILE \
                   autossh -f -M $RANDOM $HOST -N
    unset AUTOSSH_PIDFILE
    unset HOST
}

function stop_jump
{
    HOST="${1}"
    AUTOSSH_PIDFILE="${PIDDIR}/${HOST}"
    if [ ! -e $AUTOSSH_PIDFILE ] ; then
        echo "${HOST} not running"
    else
        kill $(cat $AUTOSSH_PIDFILE)
    fi
    unset AUTOSSH_PIDFILE
    unset HOST
}

function status_jump
{
    HOST="${1}"
    AUTOSSH_PIDFILE="${PIDDIR}/${HOST}"
    if [ ! -e $AUTOSSH_PIDFILE ] ; then
        echo "${HOST} not running"
    else
        ps $(cat $AUTOSSH_PIDFILE) &> /dev/null
        if [ $? == 0 ] ; then
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
                start_jump $j || problems "unable to start ${j}"
            done
        else
            start_jump $JUMP
        fi
        ;;
    stop)
        if [ "$JUMP" == "" ] ; then
            for j in $JUMPSSH_AUTO ; do
                stop_jump $j || problems "unable to stop ${j}"
            done
        else
            stop_jump $JUMP
        fi
        ;;
    status)
        if [ "$JUMP" == "" ] ; then
            for j in $JUMPSSH_AUTO ; do
                status_jump $j
            done
        else
            status_jump $JUMP
        fi
        ;;
    *)
        usage
        ;;
esac
unset JUMP
