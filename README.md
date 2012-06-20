s
=

s is the dead-simple command line ssh configuration management tool you've always wanted. Built to do one thing well—remember ssh connections and recall them as simple, single word configuration aliases. Written in bash and licensed as freeBSD so you can use it nearly everywhere.  

Installing s:

One-line auto-install latest version from github:

	wget https://raw.github.com/grobertson/s/master/bin/s -O /tmp/s && cd /tmp && chmod 700 /tmp/s && ./s --install system && rm -f /tmp/s
	
From this directory:

To install s for just the current user:

	./s --install home

To install s for everyone (requires root, or at least write permissions on /usr/local/bin):

	./s --install system   

Removing s:

To remove s from all likely install locations:
	
	./s --remove force	

Usage:

	usage: s [configuration_name|--save configuration_name][-i identity_file] user@host.com
	s show — Show available configurations
	s list — Show available configurations
	s <configuration_name> — Load configuration and ssh to remote acct/system
	s help — Display this message

CHANGELOG:

5/20/2012

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

	*make one-off keys 
	*install keys on the remote
	*clone config from remote with s installed
	*more complete coverage of ssh options (port forwarding first!)
	*list/delete/replace keys in ~/.ssh/
	*list/delete/replace keys on the remote
	*Needs a "delete" command

	

