# FoswikiVagrant

Instructions
============
Foswiki install from master github repo using Nginx or Apache as the Webserver

Tested with VirtualBox on Windows as host, *should* also work on a linux host.

You'll need to install the following three items, all are one-click type installs &mdash; very easy.
   * https://git-scm.com/downloads
   * https://www.virtualbox.org/wiki/Downloads
   * https://www.vagrantup.com/downloads.html

It's your responsibility to ensure you have versions of VirtualBox (or other VM software) and Vagrant that are mutually compatible. This is actually quite easy as the relevant software and support are really mature now. The following table list known match-ups.

| VM Provider | Required Vagrant | Notes |
| ----- | ----- | ----- |
| VirtualBox 4.3.20 to 4.3.30 | Vagrant 1.7.2+ | |
| VirtualBox 5.0.0+ | Vagrant 1.7.3+ | |
| VirtualBox 4.0+ to 4.3.18 | Vagrant 1.7.2+ | Probably works but ... If it works for you please let us know |

Earlier versions of vagrant *may* work, but the further back you are the greater the risk of failure.

Once the above installed bring up a command line prompt and do the following:

1. `git clone https://github.com/Jlevens/FoswikiVagrant <MyFoswikiVagrantDirectory>`
1. `cd <MyFoswikiVagrantDirectory>'
1. Optionally copy `default.foswiki` to `config.foswiki` and amend the small number of options to suit your needs (web-server and ports to use)
1. `vagrant up`
1. That's all folks

Then try http://localhost:8080 (or alternative port if you've defined that in `config.foswiki`) from a host browser and up should come your Foswiki site. You can login as admin with pw vagrant.

   1. `ssh` onto the VM guest with vagrant as user and pw.
   2. `sudo -i -u www-data`    &mdash; work as the user `www-data` this is deliberate: it is also the web-user
   3. Home directory of `www-data` is `/var/www`
   4. `cd fw-prod`      &mdash; this is where the Foswiki Production code is kept. In practice it's a misnomer this is a dev build at the moment. In the future a build suitable for Production use with matching Test; QA environments could be provided.
   5. `ll`  &mdash; see the Foswiki plugins provided and core.

There is the potential a move to chef, puppet, ansible (or whatever provisioners Vagrant supports) as my knowledge improves or other contributors get involved. It's also possible to stick with shell scripts if it turns out to be good enough.
