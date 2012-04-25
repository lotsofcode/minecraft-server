#!/bin/bash
# /etc/init.d/minecraft
# version 0.3.7 2012-03-06 (YYYY-MM-DD)

### BEGIN INIT INFO
# Provides:   minecraft
# Required-Start: $local_fs $remote_fs
# Required-Stop:  $local_fs $remote_fs
# Should-Start:   $network
# Should-Stop:    $network
# Default-Start:  2 3 4 5
# Default-Stop:   0 1 6
# Short-Description:    Minecraft server
# Description:    Starts the minecraft server
### END INIT INFO

# TODO
# mc install (asks to create default user)
# id $USERNAME > /dev/null ... OR ...
# grep $USERNAME /etc/passwd


#Settings
SERVICE='minecraft_server.jar'
OPTIONS='nogui'
USERNAME='minecraftuser'
WORLD='world'
MCPATH="/home/$USERNAME/mcserver"
BACKUPPATH='/media/remote.share/minecraft.backup'
CPU_COUNT=1
INVOCATION="java -Xmx1024M -Xms1024M -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalPacing -XX:ParallelGCThreads=$CPU_COUNT -XX:+AggressiveOpts -jar $SERVICE $OPTIONS"

ME=`whoami`
as_user() {
  if [ $ME == $USERNAME ] ; then
    bash -c "$1"
  else
    su - $USERNAME -c "$1"
  fi
}

div() {
  echo ' '; 
}

say() {
  echo $1;
  div
}

mc_install() {
  div
  user_exists=`grep $USERNAME /etc/passwd`
  if [ "$user_exists" != "" ]; then
    say "Username '$USERNAME' already exists, skipping creation of user.";
  else
    say "Create user: '$USERNAME'";
    sudo useradd -m $USERNAME 
    sudo passwd $USERNAME
    say "Create path: '$USERNAME'";
    sudo mkdir -p $MCPATH/bin
    sudo chown -R $USERNAME $MCPATH
  fi
  cd $MCPATH
  say "Installing as '$USERNAME' .."
  mc_update
  say "Installed: '$MCPATH' for '$USERNAME'";
  usage
  div
}

mc_start() {
  if  pgrep -u $USERNAME -f $SERVICE > /dev/null
  then
    say "$SERVICE is already running!"
  else
    echo "Starting $SERVICE..."
    cd $MCPATH
    as_user "cd $MCPATH && screen -dmS minecraft $INVOCATION"
    sleep 7
    if pgrep -u $USERNAME -f $SERVICE > /dev/null
    then
      echo "$SERVICE is now running."
    else
      echo "Error! Could not start $SERVICE!"
    fi
  fi
}

mc_saveoff() {
  if pgrep -u $USERNAME -f $SERVICE > /dev/null
  then
    echo "$SERVICE is running... suspending saves"
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"say SERVER BACKUP STARTING. Server going readonly...\"\015'"
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"save-off\"\015'"
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"save-all\"\015'"
    sync
    sleep 10
  else
    echo "$SERVICE is not running. Not suspending saves."
  fi
}

mc_saveon() {
  if pgrep -u $USERNAME -f $SERVICE > /dev/null
  then
    echo "$SERVICE is running... re-enabling saves"
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"save-on\"\015'"
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"say SERVER BACKUP ENDED. Server going read-write...\"\015'"
  else
    echo "$SERVICE is not running. Not resuming saves."
  fi
}

mc_stop() {
  if pgrep -u $USERNAME -f $SERVICE > /dev/null
  then
    echo "Stopping $SERVICE"
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"say SERVER SHUTTING DOWN IN 10 SECONDS. Saving map...\"\015'"
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"save-all\"\015'"
    sleep 10
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"stop\"\015'"
    sleep 7
  else
    echo "$SERVICE was not running."
  fi
  if pgrep -u $USERNAME -f $SERVICE > /dev/null
  then
    echo "Error! $SERVICE could not be stopped."
  else
    echo "$SERVICE is stopped."
  fi
}

mc_update() {
  if pgrep -u $USERNAME -f $SERVICE > /dev/null
  then
    say "$SERVICE is running! Will not start update."
  else
    MC_SERVER_URL=http://s3.amazonaws.com/MinecraftDownload/launcher/minecraft_server.jar?v=`date | sed "s/[^a-zA-Z0-9]/_/g"`
    as_user "cd $MCPATH && wget -q -O $MCPATH/minecraft_server.jar.update $MC_SERVER_URL"
    if [ -f $MCPATH/minecraft_server.jar.update ]
    then
      if `diff $MCPATH/$SERVICE $MCPATH/minecraft_server.jar.update >/dev/null`
      then 
        say "You are already running the latest version of $SERVICE."
      else
        as_user "mv $MCPATH/minecraft_server.jar.update $MCPATH/$SERVICE"
        say "Minecraft successfully updated."
      fi
    else
      say "Minecraft update could not be downloaded."
    fi
  fi
}

mc_backup() {
   mc_saveoff
   
   NOW=`date "+%Y-%m-%d_%Hh%M"`
   BACKUP_FILE="$BACKUPPATH/${WORLD}_${NOW}.tar"
   echo "Backing up minecraft world..."
   #as_user "cd $MCPATH && cp -r $WORLD $BACKUPPATH/${WORLD}_`date "+%Y.%m.%d_%H.%M"`"
   as_user "tar -C \"$MCPATH\" -cf \"$BACKUP_FILE\" $WORLD"

   echo "Backing up $SERVICE"
   as_user "tar -C \"$MCPATH\" -rf \"$BACKUP_FILE\" $SERVICE"
   #as_user "cp \"$MCPATH/$SERVICE\" \"$BACKUPPATH/minecraft_server_${NOW}.jar\""

   mc_saveon

   echo "Compressing backup..."
   as_user "gzip -f \"$BACKUP_FILE\""
   echo "Done."
}

mc_command() {
  command="$1";
  if pgrep -u $USERNAME -f $SERVICE > /dev/null
  then
    pre_log_len=`wc -l "$MCPATH/server.log" | awk '{print $1}'`
    echo "$SERVICE is running... executing command"
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"$command\"\015'"
    sleep .1 # assumes that the command will run and print to the log file in less than .1 seconds
    # print output
    tail -n $[`wc -l "$MCPATH/server.log" | awk '{print $1}'`-$pre_log_len] "$MCPATH/server.log"
  fi
}

usage() {
  echo "Usage: $0 {install|start|stop|update|backup|status|restart|command \"server command\"}"
}

#Start-Stop here
case "$1" in
  install)
    mc_install
    ;;
  start)
    mc_start
    ;;
  stop)
    mc_stop
    ;;
  restart)
    mc_stop
    mc_start
    ;;
  update)
    mc_stop
    mc_backup
    mc_update
    mc_start
    ;;
  backup)
    mc_backup
    ;;
  status)
    if pgrep -u $USERNAME -f $SERVICE > /dev/null
    then
      echo "$SERVICE is running."
    else
      echo "$SERVICE is not running."
    fi
    ;;
  command)
    if [ $# -gt 1 ]; then
      shift
      mc_command "$*"
    else
      echo "Must specify server command (try 'help'?)"
    fi
    ;;

  *)
  usage
  exit 1
  ;;
esac

exit 0