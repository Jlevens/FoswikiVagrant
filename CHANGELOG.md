# FoswikiVagrant

Version 0.3.2
=============
1. Added git config settings to ease git usage for any development work
   * git config --global user.name $git_user (from config.foswiki)
   * git config --global user.email $git_email (from config.foswiki)
   * git config --global credential.helper 'cache --timeout=3600'" as a standard setting

Version 0.3.1
=============
1. Restructured to place nginx and apache install code into separate shell scripts for easier maintenance.
1. Tested Apache and Nginx options both OK, earlier changes created some breakage
1. Extra Foswiki Extensions installed
  * Part of ongoing effort to work out how to install many key extensions
    * Which apt-get packages required
    * Which cpanm modules required
    * Special config work
    * pseudo-install of the Extension

Version 0.3
===========
1. Added support to use Apache or Nginx as the webserver
1. Renamed project to reflect the above
1. Removed use of directory name to pass parameters
  * This was always a quick hack 
  * It will become tedious as we add further paramters
1. Added use of `config.foswiki` file in JSON format to add mush more flexible options
  * In the repo is a `default.foswiki` which can be copied locally as `config.foswiki` to tailor the required options

A successful test using Hyper-V has been performed, note the following.
1. Vagrantfile changed to use hyperv not virtualbox
1. Vagrantfile changed to use the box=hashicorp/precise64 as ubuntu/urusty64 is not Hyper-V compatible
  * This is the older Ubuntu 12
  * We need to find a box for Hyper-V and Trusty64 that is from a trusted source and works
  * Or we create our own?
1. We needed to run the CMD prompt as administrator
1. We needed to give permission to allow network access, local firewall was involved
1. We needed to provide a username and password for SMB shares for the shared folders
1. A specific IP was created for the VM to ssh and browse. The port parameters did not apply and defaults of 22 and 80 were used 

Version 0.2
===========
The process has been slimmed down with only two files required. They are created inside the shell script which also allows me to parameterize certain elements.
 
I also now take the directory name containing the vagrantfile as parameters as follows:
 
Hostname__webport_sshport
OR
Hostname    with defaults of 8080 and 2220 (that is the directory name is the hostname)
 
For example, I have Foswiki-09__8089_2229. It's an important help when creating multiple VMs as I am doing. In addition it means that each terminal reports the Hostname so I do not get lost.

Version 0.1
===========
Vanilla Foswiki install from master github repo using Nginx as Webserver
