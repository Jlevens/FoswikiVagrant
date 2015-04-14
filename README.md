# FoswikiVagrantNginx

Here I used the information provided by Jlevens in the original repository (https://github.com/Jlevens/FoswikiVagrantNginx) and added some comments to make easier the Foswiki installation using Vagrant. Plus, I also described the steps to set up the Solr plugin extension for Foswiki. 

______

How to install Vanilla Foswiki from master github repository using Nginx as Webserver:

Tested with VirtualBox on Windows as host, "should" also work on a linux host.

You'll need to install the following two items:

   * https://www.virtualbox.org/wiki/Download_Old_Builds_4_3 &mdash; version 4.3.20 or later. I would recommend using version 4.3.30, because the newest versions of Vagrant and VirtualBox do not play together at all on Windows.
   * https://www.vagrantup.com/downloads.html &mdash; version 1.7.3 or later 

Start a command prompt as an administrator. First of all check that you have installed git and is already in the path (just wrote "path" and if you dont see it try to write "PATH %PATH%;C:\Program Files (x86)\Git\bin"). Now clone this repo into a directory and run "vagrant up" from within that directory. A box called FoswikiVagrantNginx_default_1437140983788_88993.vbox has been created, so now you can start the VM with login and pasword "vagrant".
Then try http://localhost:8080 from a host browser and up should come your Foswiki site. Here you can login as admin with pw vagrant.

______

Let's start with the Solr plugin installation:

The current plugin requires Solr 5.0.0 or later. Download it from your VM: "wget http://archive.apache.org/dist/lucene/solr/5.0.0/solr-5.0.0.tgz" (all versions in http://archive.apache.org/dist/lucene/solr/).

Next step will be to extract the software, create user and install the system service as following:

(First install java: "apt-get -y install openjdk-7-jdk")
"tar xzf solr-5.0.0.tgz"
"cd solr-5.0.0/bin/"
"./install_solr_service.sh ../../solr-5.0.0.tgz"
"service solr stop" 

Now type "service solr start" and try http://localhost:8984/solr/#/ 
