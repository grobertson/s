s
=

s is the dead-simple command line ssh configuration management tool you've always wanted. Built to do one thing well—remember ssh connections and recall them as simple, single word configuration aliases. Written in bash and licensed as freeBSD so you can use it nearly everywhere.  

https://github.com/grobertson/s/wiki

Installing s:

One-line auto-install latest version from github:

	wget -O- https://raw.github.com/grobertson/s/master/bin/s -O /tmp/s && cd /tmp && chmod 700 /tmp/s && ./s --install system && rm -f /tmp/s

	cd /tmp && wget -O- https://github.com/grobertson/s/archive/master.tar.gz | tar xz && cd s-master && make install && cd -
	
From this directory:

To install s for just the current user:

	make install

To install s for everyone (requires root, or at least write permissions on /usr/local/bin):

	PREFIX=/usr/local make install

Removing s:

	PREFIX=... make uninstall

Usage:

	usage: s [configuration_name|--save configuration_name][-i identity_file] user@host.com
	s show — Show available configurations
	s list — Show available configurations
	s <configuration_name> — Load configuration and ssh to remote acct/system
	s help — Display this message

CHANGELOG:

5/21/2012

	*Port forwarding options -L and -R are fully implemented (even multiple rules)

5/20/2012
    
	*Option to create/install/save a new 2048 bit keypair on a remote host 
	*'s --addkey [-i existing_keyfile] user@host.com NewConfigName' (no -i will prompt for password) 
	*Self install './s --install (home|system)' 
	*system option to --install uses least privledged bin ("/usr/local/bin/", "/usr/bin/", "/bin/" in order)
	*Self uninstall './s --remove force' Removes from all likely places (home, local, user, /bin)
	*Added INSTALL file
	*Added install directions to README
	
5/19/2012

	*freeBSD license added
	*create a new configuration by connecting once and passing a name to --save option
	*Humanized error when configuration name doesn't exist
	*ssh option -i recognition/handling
	*config moved to ~/.s and ~/.sconfig, autocreates

5/17/2012

	*"show" and "list" are now interchangeable
	*Hide the "template" configuration from the show/list function


4/22/2012

	*show, help and connect functions
	*include a template for basic configurations

TO-DO:

	*clone config from remote with s installed
	*more complete coverage of ssh options
	*list/delete/replace keys in ~/.ssh/
	*list/delete/replace keys on the remote
	*Needs a "delete" command

	

