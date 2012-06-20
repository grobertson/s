s
=

s is the dead-simple command line ssh configuration management tool you've always wanted. Built to do one thing well—remember ssh connections and recall them as simple, single word configuration aliases. 

	usage: s [configuration_name|--save configuration_name][-i identity_file] user@host.com
	s show — Show available configurations
	s list — Show available configurations
	s <configuration_name> — Load configuration and ssh to remote acct/system
	s help — Display this message

CHANGELOG:

5/19/2012

*create a new configuration by connecting once and passing a name to --save option
*Humanized error when configuration name doesn't exist


5/17/2012

*"show" and "list" are now interchangeable
*Hide the "template" configuration from the show/list function


4/22/2012

*show, help and connect functions
*include a template for basic configurations

TO-DO:
*more complete coverage of ssh options
*Need a "delete" command

	

