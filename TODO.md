# todo list

1. Add installation preference for server script. (i.e. home/local vs global bin installation directory)
    1. Install to /etc/init.d/minecraft (global, prefered)
    2. Install to /home/$USERNAME/minecraft/bin (optional, local)
2. Add remote update for the server script (./bin/script.sh) from GitHub :)
3. Auto install and configure crontab (for backups)
4. Auto rc.d to initialise on startup
5. Add screen command to jump to active screen via server script

# Process: bin/install.sh

1. Ask for the username to install for:
	1. Check for the user
		1. exists? Confirms to install to this user
		2. Create user
2. Check if /home/$username/mcserver/ 
	1. exists? Confirms/Ask for overwrite 
	2. Otherwise, Creates path
3. Replace $USERNAME with provided username and replace MCPATH in setup file and install to /etc/init.d/minecraft
4. Set permissions for all files
5. Invoke the start server script /etc/init.d/minecraft start
