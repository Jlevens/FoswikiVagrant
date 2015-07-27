# FoswikiVagrantNginx

Here I used the information provided by Jlevens in the original repository (https://github.com/Jlevens/FoswikiVagrantNginx) and added some comments to make easier the Foswiki installation using Vagrant. Plus, I also described the steps to set up the Solr plugin extension for Foswiki. 

______

How to install Vanilla Foswiki from master github repository using Nginx as Webserver:

Tested with VirtualBox on Windows as host, "should" also work on a linux host.

You'll need to install the following two items:

   * https://www.virtualbox.org/wiki/Download_Old_Builds_4_3 &mdash; version 4.3.20 or later. I would recommend using version 4.3.30, because the newest versions of Vagrant and VirtualBox do not play together at all on Windows.
   * https://www.vagrantup.com/downloads.html &mdash; version 1.7.3 or later 

Start a command prompt as an administrator. First of all check that you have installed git and is already in the path. Now clone this repo into a directory and run "vagrant up" from within that directory. 
Then try http://localhost:8080 from a host browser and up should come your Foswiki site. Here you can login as admin with password vagrant.

______

Let's start with the Solr plugin installation:

To do this I mainly followed the steps described in http://foswiki.org/Extensions/SolrPlugin 

A box called FoswikiVagrantNginx_default_"something".vbox was created when you did "vagrant up", so now you can start to use this VM with login and pasword "vagrant" (if the sesion was aborted, restart the computer and try again!).

Once Foswiki is running in your host machine, go to http://localhost:8080/bin/configure .Now open the "Extensions" section. Select "Install, Update or Remove extensions", "search for extension", Extension name= SolrPlugin, select "Find extension" and select "Install" (after doing this could be some missing stuff that you may have to fix later, don't worry). Don't forget to save (in the top-right corner of the page) the changes!!

The current plugin requires Solr 5.0.0 or later. Next step will be download it from your VM: "wget http://archive.apache.org/dist/lucene/solr/5.0.0/solr-5.0.0.tgz" .You can find all the versions in http://archive.apache.org/dist/lucene/solr/ . I'll use Solr 5.0.0 so, if you use a different one, don't forget to change the following comands!

Next step will be to extract the software, create user and install the system service as follows:

	(First install java as root: "apt-get -y install openjdk-7-jdk")
 	tar xzf solr-5.0.0.tgz solr-5.0.0/bin/install_solr_service.sh 
	cd solr-5.0.0/bin/
	./install_solr_service.sh ../../solr-5.0.0.tgz
	service solr stop

(If you want to add some secure Solr access then check http://foswiki.org/Extensions/SolrPlugin ).

Now type "service solr start" and try http://localhost:8984/solr/#/  (don't forget that this will not work if you have added the secure Solr access, but you can just uncomment what you added or change Djetty.host=localhost by  Djetty.host=0.0.0.0 ).Would also work to start solr like this: ./solr start -h 0.0.0.0


It's recommended to relocate the logs as described in http://foswiki.org/Extensions/SolrPlugin :

	edit /var/solr/solr.in.sh -> disable garbage collection logs ... GC_LOG_OPTS and set SOLR_LOGS_DIR=/var/log/solr

	edit /var/solr/log4j.properties -> set solr.log=/var/log/solr

To install the Foswiki configuration set:

	(In my case <foswiki-dir>=var/www/fw-prod/core)
	cd /var/solr/data 
	cp -r /<foswiki-dir>/solr/configsets . 
	cp -r /<foswiki-dir>/solr/cores . 
	chown -R solr.solr .


Is time to test the indexer:

	service solr start
	cd /<foswiki-dir>/tools 
	./solrindex topic=Main.WebHome

This may fails because of the missing stuff while installing the SolrPlugin. To install moose, xml-easy and mmagic perl:

	apt-get update
	apt-get install libany-moose-perl
	apt-get install libxml-easy-perl
	apt-get install libfile-mmagic-perl

Now go to <foswiki-dir>/lib/Localsite.cfg and check that you have this configuration (if not, change it):

	$Foswiki::cfg{Plugins}{SolrPlugin}{Module} = 'Foswiki::Plugins::SolrPlugin';

Now try again:
	
	./solrindex topic=Main.WebHome

and look for the index you just created -> http://localhost:8080/System/SolrSearch 

Well, you have finished installing Foswiki!

