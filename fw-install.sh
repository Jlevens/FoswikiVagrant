# -----------------------------------------------------------------------------
# Get arguments from Vagrantfile

www_port=$1
web_serv=$2

if [ "$web_serv" == "nginx" ]
then
    source "/home/vagrant/nginx_install.sh"
else
    source "/home/vagrant/apache_install.sh"
fi

# Started getting 404 accessing http://security.ubuntu.com, error came back with this suggestion
apt-get update

# curl -L https://cpanmin.us | perl - --sudo App::cpanminus
apt-get install -y cpanminus

# cpanm --sudo --mirror file:///vCPAN \
cpanm --sudo --skip-installed \
   HTML::Entities \
   HTML::Entities::Numbered \
   HTML::TreeBuilder \
   Lingua::EN::Sentence \
   Mozilla::CA \
   URI::Escape \
   Crypt::Eksblowfish::Bcrypt \
   Win32::Console \
   Time::ParseDate


# cpanm POSIX   N/A core perl

# cpan modules not really required
#  Crypt::Eksblowfish::Bcrypt                Only for bcrypt support on passwords
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

# give www-data a shell that way we can 'sudo -i -u www-data' later
chsh -s /bin/bash www-data

# -----------------------------------------------------------------------------
# Setup web site folders

mkdir --parents /var/www/fw-prod

chown www-data:www-data /var/www/.*
chown www-data:www-data /var/www

# Give www-data passwordless sudo rights
#-- sudoers.d/www-data-----------------------------------------------------------------------------------
cat <<EOF > /etc/sudoers.d/www-data
www-data ALL=(ALL:ALL) NOPASSWD: ALL
EOF
#-- sudoers.d/www-data-----------------------------------------------------------------------------------

# Create usual .config files for www-data, plus set up some useful env variables
# (www-data is already set with /var/www as it's home directory)

cp -rvt /var/www `find /etc/skel -name '.*'`

#-- /var/www/.bashrc-----------------------------------------------------------------------------------
cat <<EOF >> /var/www/.bashrc

# Create some useful fw_* ENVironment variables
fw_http='/etc/nginx/sites-available/fw-prod.conf'
fw_init='/etc/init.d/fw-prod'
fw_httplog='/var/log/nginx/fw-prod.log'
export fw_http fw_init fw_httplog
EOF
#-- /var/www/.bashrc-----------------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Set up web server, Apache or Nginx

web_serv_install $www_port

cd /var/www
git clone https://github.com/foswiki/distro.git fw-prod
chown -R www-data:www-data fw-prod

cd fw-prod/core
sudo -u www-data perl -T pseudo-install.pl developer
sudo -u www-data perl -T pseudo-install.pl FastCGIEngineContrib

# Bootstrap configure
sudo -u www-data perl tools/configure \
  -noprompt \
  -set {DefaultUrlHost}="http://localhost:$web_port" \
  -set {ScriptUrlPath}='' \
  -set {ScriptUrlPaths}{view}='' \
  -set {PubUrlPath}='/pub' \
  -set {Password}='vagrant' \
  -set {ScriptDir}='/var/www/fw-prod/core/bin' \
  -set {ScriptSuffix}='' \
  -set {DataDir}='/var/www/fw-prod/core/data' \
  -set {PubDir}='/var/www/fw-prod/core/pub' \
  -set {TemplateDir}='/var/www/fw-prod/core/templates' \
  -set {LocalesDir}='/var/www/fw-prod/core/locale' \
  -set {WorkingDir}='/var/www/fw-prod/core/working' \
  -set {ToolsDir}='/var/www/fw-prod/core/tools' \
  -set {Store}{Implementation}='Foswiki::Store::PlainFile' \
  -set {Store}{SearchAlgorithm}='Foswiki::Store::SearchAlgorithms::PurePerl' \
  -set {SafeEnvPath}='/bin:/usr/bin' \
  -save

sudo -u www-data perl -T pseudo-install.pl ActionTrackerPlugin

sudo -u www-data perl -T pseudo-install.pl AutoViewTemplatePlugin

sudo -u www-data perl -T pseudo-install.pl CalendarPlugin
apt-get install -y libdate-calc-perl
apt-get install -y HTML::CalendarMonthSimple

sudo -u www-data perl -T pseudo-install.pl ChartPlugin
apt-get install -y libgd3
apt-get install -y libgd-perl
##   POSIX	>0	CoreList
##   File::Path	>0	CoreList 

sudo -u www-data perl -T pseudo-install.pl ChecklistPlugin

sudo -u www-data perl -T pseudo-install.pl ControlWikiWordPlugin

#  DirectedGraphPlugin

sudo -u www-data perl -T pseudo-install.pl EasyMacroPlugin

sudo -u www-data perl -T pseudo-install.pl ExplicitNumberingPlugin

sudo -u www-data perl -T pseudo-install.pl FilterPlugin

sudo -u www-data perl -T pseudo-install.pl FindElsewherePlugin

sudo -u www-data perl -T pseudo-install.pl FlotChartPlugin

sudo -u www-data perl -T pseudo-install.pl MenuListPlugin

sudo -u www-data perl -T pseudo-install.pl RedirectPlugin

sudo -u www-data perl -T pseudo-install.pl RenderPlugin

sudo -u www-data perl -T pseudo-install.pl TopicCreatePlugin

sudo -u www-data perl -T pseudo-install.pl TreePlugin

sudo -u www-data perl -T pseudo-install.pl UpdateAttachmentsPlugin


web_serv_start $www_port

# GenPDFAddOn

# Part of SSO support?
#   LdapContrib
#   LdapNgPlugin
#   NewUserPlugin

# Hopefully http://localhost:$web_port will now bring up the foswiki Main/WebHome topic
