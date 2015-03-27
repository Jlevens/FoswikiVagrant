
# Our vagrantfile will provision a CPAN Config file for unattended install
# Run cpan before apt-get, otherwise this Config file is not picked up

cpan                                         \
  HTML::Entities                             \
  HTML::Entities::Numbered                   \
  HTML::TreeBuilder                          \
  Lingua::EN::Sentence                       \
  Mozilla::CA                                \
  POSIX                                      \
  URI::Escape

# cpan modules not really required
#  Crypt::Eksblowfish::Bcrypt                Only for bcrypt support on passwords
#  Encode::compat                            Only if perl < 5.7.1 as we only suport perl 5.8+ this does not apply
#  Win32::Console                            Only for Windows


apt-get install -y rcs # Required for legacy RCS stores moving to PFS now as default

apt-get install -y libdigest-sha-perl
apt-get install -y libhtml-entities-numbered-perl
apt-get install -y perltidy

# As scanned from DEPENDENCIES files of distro

# This block is generally core perl modules (some exceptions) so no need to install
# apt-get install -y libb-deparse-perl
# apt-get install -y libcarp-perl
# apt-get install -y libcgi-perl
# apt-get install -y libconfig-perl
# apt-get install -y libcwd-perl
# apt-get install -y libdata-dumper-perl
# apt-get install -y libexporter-perl
# apt-get install -y libfile-basename-perl
# apt-get install -y libfile-copy-perl
# apt-get install -y libfile-find-perl
# apt-get install -y libfile-glob-perl
# apt-get install -y libfilehandle-perl
# apt-get install -y libfindbin-perl
# apt-get install -y libgetopt-long-perl
# apt-get install -y libi18n-langinfo-perl
# apt-get install -y libio-file-perl
# apt-get install -y liblocale-country-perl
# apt-get install -y liblocale-language-perl
# apt-get install -y libnet-smtp-perl
# apt-get install -y libpod-usage-perl
# apt-get install -y libsymbol-perl
# apt-get install -y libuniversal-perl

# Extra perl libraries required
apt-get install -y libalgorithm-diff-perl
apt-get install -y libapache-htpasswd-perl
apt-get install -y libarchive-tar-perl
apt-get install -y libarchive-zip-perl
apt-get install -y libauthen-sasl-perl
apt-get install -y libcgi-session-perl
apt-get install -y libcrypt-passwdmd5-perl
apt-get install -y libcss-minifier-perl
apt-get install -y libdevel-symdump-perl
apt-get install -y libdigest-md5-perl
apt-get install -y libdigest-sha-perl
apt-get install -y libencode-perl
apt-get install -y liberror-perl
apt-get install -y libfcgi-perl
apt-get install -y libfile-copy-recursive-perl
apt-get install -y libfile-path-perl
apt-get install -y libfile-remove-perl
apt-get install -y libfile-spec-perl
apt-get install -y libfile-temp-perl
apt-get install -y libhtml-parser-perl
apt-get install -y libhtml-tidy-perl
apt-get install -y libhtml-tree-perl
apt-get install -y libimage-magick-perl
apt-get install -y libio-socket-ip-perl
apt-get install -y libio-socket-ssl-perl
apt-get install -y libjavascript-minifier-perl
apt-get install -y libjson-perl
apt-get install -y liblocale-maketext-perl
apt-get install -y liblocale-msgfmt-perl
apt-get install -y libmime-base64-perl
apt-get install -y libsocket-perl
apt-get install -y liburi-perl
apt-get install -y libversion-perl

# Needed by git hooks
apt-get install -y libtext-diff-perl

apt-get install -y git
apt-get install -y nginx

# give www-data a shell that way we can 'sudo -i -u www-data' later
chsh -s /bin/bash www-data

cp /vagrant/fw-prod.conf /etc/nginx/sites-available/fw-prod.conf
cp /vagrant/fw-prod.init /etc/init.d/fw-prod

mkdir /var/www
mkdir /var/www/fw-prod

# Give www-data passwordless sudo rights
cp /vagrant/www-data /etc/sudoers.d/www-data

# Create usual .config files for www-data, plus set up some useful/adjusted extra aliases
# (www-data is already set with /var/www as it's home directory)
cp /etc/skel/.* /var/www # Complains about omitting '.' & '..', but so what
cp /vagrant/bash_aliases /var/www/.bash_aliases
chown www-data:www-data /var/www/.*

chown www-data:www-data /var/www
chown www-data:www-data /etc/nginx/sites-available/fw-prod.conf
chown www-data:www-data /etc/init.d/fw-prod
mkdir /var/log/www
touch /var/log/www/fw-prod.log
chown www-data:www-data /var/log/www
chown www-data:www-data /var/log/www/fw-prod.log

service nginx stop
rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/fw-prod.conf /etc/nginx/sites-enabled/fw-prod.conf
service nginx start

cd /var/www
git clone https://github.com/foswiki/distro.git fw-prod
chown -R www-data:www-data fw-prod

cd fw-prod/core
sudo -u www-data perl -T pseudo-install.pl developer
sudo -u www-data perl -T pseudo-install.pl FastCGIEngineContrib

# FastCGI cannot yet bootstrap configure, so we do what we need here
cp /vagrant/LocalSite.cfg /var/www/fw-prod/core/lib/LocalSite.cfg
chown www-data:www-data /var/www/fw-prod/core/lib/LocalSite.cfg
#sudo -u www-data perl configure \
#  -set {DefaultUrlHost}='http://localhost:8080' \
#  -set {ScriptUrlPath}='' \
#  -set {ScriptUrlPaths}{view}='' \
#  -set {PubUrlPath}='/pub' \
#  -set {Password}='vagrant' \
#  -set {ScriptDir}='/var/www/fw-prod/core/bin' \
#  -set {ScriptSuffix}='' \
#  -set {DataDir}='/var/www/fw-prod/core/data' \
#  -set {PubDir}='/var/www/fw-prod/core/pub' \
#  -set {TemplateDir}='/var/www/fw-prod/core/templates' \
#  -set {LocalesDir}='/var/www/fw-prod/core/locale' \
#  -set {WorkingDir}='/var/www/fw-prod/core/working' \
#  -set {ToolsDir}='/var/www/fw-prod/core/tools' \
#  -set {Store}{Implementation}='Foswiki::Store::PlainFile' \
#  -set {Store}{SearchAlgorithm}='Foswiki::Store::SearchAlgorithms::Forking' \
#  -save

service fw-prod start
update-rc.d fw-prod defaults

# Hopefully http://localhost:8080 will now bring up the foswiki Main/WebHome topic

#apt-get install -y openjdk-7-jre
#apt-get install -y unzip

#sed -i -r '/^solr\.log=/ s/=.*/=\/var\/log\/solr/' /var/solr/log4j.properties
