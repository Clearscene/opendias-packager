#! /bin/sh

### BEGIN INIT INFO
# Provides:          <my_app> application instance
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts instance of <my_app> app
# Description:       starts instance of <my app> app using start-stop-daemon
### END INIT INFO

# path to app
APP_PATH=/usr/local/sbin/

# path to paster bin
DAEMON=/usr/local/sbin/opendias

# startup args
DAEMON_OPTS=""

# script name
NAME=clearscene-opendias.sh

# app name
DESC=opendias

# pylons user
RUN_AS=root

PID_FILE=/var/run/opendias.pid


test -x $DAEMON || exit 0

set -e

case "$1" in
  start)
        echo -n "Starting $DESC: "
        start-stop-daemon -d $APP_PATH -c $RUN_AS --start --pidfile $PID_FILE --exec $DAEMON -- $DAEMON_OPTS
        echo "$NAME."
        ;;
  stop)
        echo -n "Stopping $DESC: "
        start-stop-daemon --stop --pidfile $PID_FILE
        echo "$NAME."
        ;;

  restart|force-reload)
        echo -n "Restarting $DESC: "
        start-stop-daemon --stop --pidfile $PID_FILE
        sleep 1
        start-stop-daemon -d $APP_PATH -c $RUN_AS --start --pidfile $PID_FILE --exec $DAEMON -- $DAEMON_OPTS
        echo "$NAME."
        ;;
  *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac

exit 0
