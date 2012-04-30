#!/bin/bash
# install script

#SERVICE='[SERVICE_NAME]'
#OPTIONS='nogui'
#USERNAME='[USER_NAME]'
#WORLD='[WORLD_NAME]'
#MCPATH="/home/[USER_NAME]/[SERVER_DIR_NAME]"
#BACKUPPATH='[BACKUP_PATH]'

# Cleanup

#sudo userdel minecraft
#sudo rm -fr /home/minecraft
#sudo rm /etc/init.d/mcserver
#sudo rm /usr/local/bin/mcserver

# Default Settings
  
  DEFAULT_MCSERVER='/etc/init.d/mcserver'
  DEFAULT_MCSERVER_ALIAS='mcserver'
  DEFAULT_USER_NAME='minecraft';
  DEFAULT_WORLD_NAME='world';
  DEFAULT_SERVER_DIR_NAME='mcserver';
  DEFAULT_BACKUP_PATH='backups';
  DEFAULT_SERVICE_NAME='minecraft_server.jar';
  SERVICE_NAME=$DEFAULT_SERVICE_NAME;

# User settings

  echo -n "Please choose a username for the server to be run as (default '$DEFAULT_USER_NAME'): ";
  read USER_NAME

  if [ "$USER_NAME" = "" ]; then
    USER_NAME=$DEFAULT_USER_NAME;
  fi

  echo -n "Please enter a world name (default '$DEFAULT_WORLD_NAME'): ";
  read WORLD_NAME

  if [ "$WORLD_NAME" = "" ]; then
    WORLD_NAME=$DEFAULT_WORLD_NAME;
  fi

  echo -n "Please enter the directory where the server will be run from (default '$DEFAULT_SERVER_DIR_NAME'): ";
  read SERVER_DIR_NAME

  if [ "$SERVER_DIR_NAME" = "" ]; then
    SERVER_DIR_NAME=$DEFAULT_SERVER_DIR_NAME;
  fi

  echo -n "Please choose your server command install path (default '$DEFAULT_MCSERVER'): ";
  read MCSERVER

  if [ "$MCSERVER" = "" ]; then
    MCSERVER=$DEFAULT_MCSERVER
  fi

  echo -n "Please choose your server command (default '$DEFAULT_MCSERVER_ALIAS'): ";
  read MCSERVER_ALIAS

  if [ "$MCSERVER_ALIAS" = "" ]; then
    MCSERVER_ALIAS=$DEFAULT_MCSERVER_ALIAS
  fi

  MCPATH="/home/$USER_NAME/$SERVER_DIR_NAME"
  DEFAULT_BACKUP_PATH="$MCPATH/$DEFAULT_BACKUP_PATH";

  echo -n "Please enter a backup path (default '$DEFAULT_BACKUP_PATH'): ";
  read BACKUP_PATH

  if [ "$BACKUP_PATH" = "" ]; then
    BACKUP_PATH=$DEFAULT_BACKUP_PATH
  fi

# Create user

  user_exists=`grep $USER_NAME /etc/passwd`
  if [ "$user_exists" != "" ]; then
    echo "Username '$USER_NAME' already exists, skipping creation of user.";
  else
    sudo useradd -m $USER_NAME  && sudo passwd $USER_NAME
    sudo mkdir -p $MCPATH/backups && sudo chown -R $USER_NAME $MCPATH
    echo "Created user: '$USER_NAME'";
  fi

# Create server script

  CREATE_INIT="y"
  if [ -e "$MCSERVER" ]; then
    CREATE_INIT="y"
    echo -n "$MCSERVER exists, replace? (y/n) ";
    read REPLACE_INIT;
    CREATE_INIT=$REPLACE_INIT
  fi

  # Yuk, we need to escape / 
  # @see http://stackoverflow.com/questions/407523/escape-a-string-for-sed-search-pattern
  BACKUP_PATH=$(echo $BACKUP_PATH | sed -e 's/[\/&]/\\&/g');

  if [ "$CREATE_INIT" = "y" ]; then
    sed -e "s/REPLACE_USER_NAME/$USER_NAME/g" \
        -e "s/REPLACE_WORLD_NAME/$WORLD_NAME/g" \
        -e "s/REPLACE_SERVER_DIR_NAME/$SERVER_DIR_NAME/g" \
        -e "s/REPLACE_BACKUP_PATH/$BACKUP_PATH/g" \
        -e "s/REPLACE_SERVICE_NAME/$SERVICE_NAME/g" bin/server.sh > /tmp/minecraft_server;
    sudo cp /tmp/minecraft_server $MCSERVER && sudo chmod +x $MCSERVER
    if [ ! -h /usr/local/bin/$MCSERVER_ALIAS ]; then
      sudo ln -s $MCSERVER /usr/local/bin/$MCSERVER_ALIAS 
    fi
  fi

# Invoke the update

#  $MCSERVER update

# tmp output
  echo -n 'USER_NAME:';
    echo $USER_NAME;
  echo -n 'WORLD_NAME:';
    echo $WORLD_NAME;
  echo -n 'SERVER_DIR_NAME:';
    echo $SERVER_DIR_NAME;
  echo -n 'BACKUP_PATH:';
    echo $BACKUP_PATH;
  echo -n 'SERVICE_NAME:';
    echo $SERVICE_NAME;

  echo -n 'MCSERVER:';
    echo $MCSERVER;
  echo -n 'MCSERVER_ALIAS:';
    echo $MCSERVER_ALIAS;
 echo -n 'CREATE_INIT:';
    echo $CREATE_INIT;
  echo -n 'REPLACE_INIT:';
    echo $REPLACE_INIT;

exit 1;