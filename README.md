# FoswikiVagrantNginx
Vanilla Foswiki install from master github repo using Nginx as Webserver

Tested with VirtualBox on Windows as host, *should* also work on a linux host.

You'll need to install the following two items, both are one-click type installs &mdash; very easy.
   * https://www.virtualbox.org/wiki/Downloads
   * https://www.vagrantup.com/downloads.html

Clone this repo into a directory then run 'vagrant up' from within that directory, that's all it needs.
  
Inspired by https://github.com/Babar/foswiki-vagrant which I used for some time.

However, I had difficulties using the Foswiki build tools in the Windows host. So I decided to start from scratch, in part to learn and understand the process better. Chose to start developing with shell scripts as recommended by Vagrant documentation.

There is the potential a move to chef, puppet, ansible (or whatever provisioners Vagrant supports) as my knowledge and improves or other contributors get involved. It's also possible to stick with shell scripts if it turns out to be good enough.
