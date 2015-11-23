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
apt-get install -y -qq cpanminus

# cpanm --sudo --mirror file:///vCPAN \
cpanm --sudo --skip-installed -q \
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

apt-get install -y -qq rcs # Required for legacy RCS stores moving to PFS now as default

apt-get install -y -qq libdigest-sha-perl
apt-get install -y -qq libhtml-entities-numbered-perl
apt-get install -y -qq perltidy

# As scanned from DEPENDENCIES files of distro

# This block is generally core perl modules (some exceptions) so no need to install
# apt-get install -y -qq libb-deparse-perl
# apt-get install -y -qq libcarp-perl
# apt-get install -y -qq libcgi-perl
# apt-get install -y -qq libconfig-perl
# apt-get install -y -qq libcwd-perl
# apt-get install -y -qq libdata-dumper-perl
# apt-get install -y -qq libexporter-perl
# apt-get install -y -qq libfile-basename-perl
# apt-get install -y -qq libfile-copy-perl
# apt-get install -y -qq libfile-find-perl
# apt-get install -y -qq libfile-glob-perl
# apt-get install -y -qq libfilehandle-perl
# apt-get install -y -qq libfindbin-perl
# apt-get install -y -qq libgetopt-long-perl
# apt-get install -y -qq libi18n-langinfo-perl
# apt-get install -y -qq libio-file-perl
# apt-get install -y -qq liblocale-country-perl
# apt-get install -y -qq liblocale-language-perl
# apt-get install -y -qq libnet-smtp-perl
# apt-get install -y -qq libpod-usage-perl
# apt-get install -y -qq libsymbol-perl
# apt-get install -y -qq libuniversal-perl

# Extra perl libraries required
apt-get install -y -qq libalgorithm-diff-perl
apt-get install -y -qq libapache-htpasswd-perl
apt-get install -y -qq libarchive-tar-perl
apt-get install -y -qq libarchive-zip-perl
apt-get install -y -qq libauthen-sasl-perl
apt-get install -y -qq libcgi-session-perl
apt-get install -y -qq libcrypt-passwdmd5-perl
apt-get install -y -qq libcss-minifier-perl
apt-get install -y -qq libdevel-symdump-perl
apt-get install -y -qq libdigest-md5-perl
apt-get install -y -qq libdigest-sha-perl
apt-get install -y -qq libencode-perl
apt-get install -y -qq liberror-perl
apt-get install -y -qq libfcgi-perl
apt-get install -y -qq libfile-copy-recursive-perl
apt-get install -y -qq libfile-path-perl
apt-get install -y -qq libfile-remove-perl
apt-get install -y -qq libfile-spec-perl
apt-get install -y -qq libfile-temp-perl
apt-get install -y -qq libhtml-parser-perl
apt-get install -y -qq libhtml-tidy-perl
apt-get install -y -qq libhtml-tree-perl
apt-get install -y -qq libimage-magick-perl
apt-get install -y -qq libio-socket-ip-perl
apt-get install -y -qq libio-socket-ssl-perl
apt-get install -y -qq libjavascript-minifier-perl
apt-get install -y -qq libjson-perl
apt-get install -y -qq liblocale-maketext-perl
apt-get install -y -qq liblocale-msgfmt-perl
apt-get install -y -qq libmime-base64-perl
apt-get install -y -qq libsocket-perl
apt-get install -y -qq liburi-perl
apt-get install -y -qq libversion-perl

# Needed by git hooks
apt-get install -y -qq libtext-diff-perl
apt-get install -y -qq git

# Needed by for development work (e.g. UnitTests)
apt-get install -y -qq libtaint-runtime-perl

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

# SMELL: Failure occurs if .htpasswd doesn't exist (is it really relevant? why/where is this file even checked?)
sudo -u www-data touch /var/www/fw-prod/core/data/.htpasswd
sudo -u www-data touch /var/www/fw-prod/core/working/htpasswd.lock

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

sudo -u www-data perl -T pseudo-install.pl -e ActionTrackerPlugin

sudo -u www-data perl -T pseudo-install.pl -e AutoViewTemplatePlugin

sudo -u www-data perl -T pseudo-install.pl -e CalendarPlugin
apt-get install -y -qq libdate-calc-perl
apt-get install -y -qq HTML::CalendarMonthSimple

sudo -u www-data perl -T pseudo-install.pl -e ChartPlugin
apt-get install -y -qq libgd3
apt-get install -y -qq libgd-perl
##   POSIX	>0	CoreList
##   File::Path	>0	CoreList 

sudo -u www-data perl -T pseudo-install.pl -e ChecklistPlugin

sudo -u www-data perl -T pseudo-install.pl -e ControlWikiWordPlugin


apt-get install -y -qq graphviz
apt-get install -y -qq ghostscript
apt-get install -y -qq imagemagick

# This is *really* optional, requires updating /etc/apt/sources.list and also accepting a EULA requires user interaction
# It would be reasonable for the user to install manually after everything else. I may amend sources.list anyway as it appears
# to be generally useful (apache2 and this so far)
# Better to see updates to /etc/apt/sources.list as another dependency
# apt-get install -y -qq msttcorefonts
sudo -u www-data perl -T pseudo-install.pl -e DirectedGraphPlugin

sudo -u www-data perl -T pseudo-install.pl -e ExplicitNumberingPlugin

sudo -u www-data perl -T pseudo-install.pl -e FilterPlugin

sudo -u www-data perl -T pseudo-install.pl -e FindElsewherePlugin

sudo -u www-data perl -T pseudo-install.pl -e FlotChartPlugin

sudo -u www-data perl -T pseudo-install.pl -e MenuListPlugin

sudo -u www-data perl -T pseudo-install.pl -e RedirectPlugin

sudo -u www-data perl -T pseudo-install.pl -e RenderPlugin

sudo -u www-data perl -T pseudo-install.pl -e TopicCreatePlugin

sudo -u www-data perl -T pseudo-install.pl -e TreePlugin

sudo -u www-data perl -T pseudo-install.pl -e UpdateAttachmentsPlugin

sudo -u www-data perl -T pseudo-install.pl -e WorkflowPlugin

sudo -u www-data perl -T pseudo-install.pl -e NewUserPlugin


apt-get install -y -qq libauthen-sasl-perl
# DB_File is core perl so no package available
apt-get install -y -qq libdb-file-lock-perl
# Digest::MD5 is core perl
# GSSAPI optional
# IO::Socket::INET6 optional
apt-get install -y -qq libio-socket-ssl-perl
apt-get install -y -qq libnet-ldap-perl

sudo -u www-data perl -T pseudo-install.pl -e LdapContrib


apt-get install -y -qq libcache-cache-perl
sudo -u www-data perl -T pseudo-install.pl -e LdapNgPlugin

sudo -u www-data perl -T pseudo-install.pl -e BehaviourContrib

# Required to run Unit Tests
FOSWIKI_HOME=/var/www/fw-prod/core
export FOSWIKI_HOME

# Now CGI is out of core perl and HTML gen stuff gone, do we need an earlier version?
cpanm --sudo --skip-installed -q CGI
# Data::Dumper,>=0,cpan  CORE Perl
apt-get install -y -qq liberror-perl
# File::Temp,>=0,cpan    CORE Perl
apt-get install -y -qq htmldoc

sudo -u www-data perl -T pseudo-install.pl -e GenPDFAddOn
sudo -u www-data perl tools/configure -noprompt \
  -set {Extensions}{GenPDFAddOn}{htmldocCmd}='/usr/bin/htmldoc' \
  -set {Plugins}{GenPDFAddOnPlugin}{Enabled}=1 \
  -set {Plugins}{GenPDFAddOnPlugin}{Module}='Foswiki::Plugins::GenPDFAddOnPlugin' \
  -save

# Templates have not been updated to include a genpdf option
# That will need further thought
# For now on a particular page change server/Web/Topic to server/bin/genpdf/Web/Topic
# Can also add '* Set SKIN = genpdf, pattern' on SitePreferences page



# --- StringifierContrib is required by SolrPlugin ------------------------------------------------
# Foswiki::Contrib::StringifierContrib	>=1.20	Required

# File::Which	>0	Required
apt-get install -qq -y libfile-which-perl
# Module::Pluggable	>0	Required
apt-get install -qq -y libmodule-pluggable-perl
# Spreadsheet::ParseExcel	>0	Required for .xls files
apt-get install -qq -y libspreadsheet-parseexcel-perl
# Spreadsheet::XLSX	>0	Required for .xlsx files
apt-get install -qq -y libspreadsheet-xlsx-perl

# Encode	>0	Required
# Core Perl
# Error	>0	Required
apt-get install -y -qq liberror-perl

# catdoc	>0	Optional

# ppthtml	>0	Required
apt-get install -qq -y ppthtml
# pdftotext	>0	Required for indexing .pdf. Part of poppler-utils
apt-get install -qq -y poppler-utils


# soffice	>0	One of antiword, abiword, soffice or wvWare is required for .doc and .docx files
# antiword	>0	One of antiword, abiword, soffice or wvWare is required for .doc files
# abiword	>0	One of antiword, abiword, soffice or wvWare is required for .doc files
# wvWare	>0	One of antiword, abiword, soffice or wvWare is required for .doc files

# I chose abiword as it has recent development
# wvWare project deprecates their own utilities in favour of abiword (which use wv library which is actively developed)
# I do wonder if LibreOffice would provide much more up to date format support while also covering odt2txt capability
# Apache Open Office is an alternative as is NeoOffice for OsX - they are all close open source cousins
apt-get install -qq -y abiword


# html2text	>0	Required for indexing html files
apt-get install -qq -y html2text

# odt2txt	>0	Required for indexing OpenDocument and StarOffice documents
apt-get install -qq -y odt2txt

sudo -u www-data perl -T pseudo-install.pl -e StringifierContrib



# --- XSendFileContrib is required by ImagePlugin -------------------------

# Foswiki::Contrib::FastCGIEngineContrib	>=0.9.5	Optional.
# File:MMagic	>=0	Required
apt-get install -qq -y libfile-mmagic-perl
sudo -u www-data perl -T pseudo-install.pl -e XSendFileContrib



# --- ImagePlugin is required for SolrPlugin and it has a few dependencies -------------------------

# LWP::UserAgent	>=0	Required
apt-get install -y -qq libwww-perl
# Image::Magick	>=6.2.4.5	Required
apt-get install -qq -y libimage-magick-perl




# --- Solr has a lot of dependencies and config to do as follows -----------------------------------

#Foswiki::Plugins::AutoTemplatePlugin	>=1.0	Optional
#Foswiki::Plugins::ClassificationPlugin	>=1.0	Optional
#Foswiki::Plugins::DBCachePlugin	>=1	Optional

# Foswiki::Contrib::JQMomentContrib	>=1.0	Required
sudo -u www-data perl -T pseudo-install.pl -e JQMomentContrib
# Foswiki::Contrib::JQPrettyPhotoContrib	>=1.0	Required
sudo -u www-data perl -T pseudo-install.pl -e JQPrettyPhotoContrib
# Foswiki::Contrib::JQSerialPagerContrib	>=1.0	Required
sudo -u www-data perl -T pseudo-install.pl -e JQSerialPagerContrib
# Foswiki::Contrib::JQTwistyContrib	>=1.0	Required
sudo -u www-data perl -T pseudo-install.pl -e JQTwistyContrib
# Foswiki::Plugins::FilterPlugin	>=2.0	Required
sudo -u www-data perl -T pseudo-install.pl -e FilterPlugin
# Foswiki::Plugins::FlexWebListPlugin	>=1.91	Required
sudo -u www-data perl -T pseudo-install.pl -e FlexWebListPlugin


cpanm --sudo --skip-installed -q \
  HTML::Entities \
  Cache::FileCache

apt-get install -y -qq libwww-perl
# OR cpanm --sudo --skip-installed -q LWP::UserAgent


apt-get install -y -qq libany-moose-perl
apt-get install -y -qq libjson-xs-perl
apt-get install -y -qq libxml-easy-perl

apt-get install -y -qq default-jre
# This might be redundant if jre also installed
apt-get install -y -qq unzip

pushd /var/www

wget http://archive.apache.org/dist/lucene/solr/5.3.1/solr-5.3.1.tgz -o wgetsolr.log
tar xzf solr-5.3.1.tgz solr-5.3.1/bin/install_solr_service.sh --strip-components 2

# Stop solr starting in the 1st place
# We need to config stuff for Foswiki before we start it
sudo -u www-data perl -i -lpe 's{^service(.*?)$}{# service$1}' ./install_solr_service.sh
sudo -u www-data perl -i -lpe 's{^sleep(.*?)$}{# sleep$1}' ./install_solr_service.sh

./install_solr_service.sh ./solr-5.3.1.tgz
# service solr stop

popd
sudo -u www-data perl -T pseudo-install.pl -e SolrPlugin
sudo -u www-data perl tools/configure -noprompt -save

mv /var/solr/logs /var/log/solr

cat <<EOF >> /var/solr/solr.in.sh
unset GC_LOG_OPTS
SOLR_LOGS_DIR=/var/log/solr
SOLR_OPTS="$SOLR_OPTS -Djetty.host=localhost"
EOF

sudo -u www-data perl -i -lpe 's{^solr.log=[^\\n]*?$}{solr.log=/var/log/solr}' /var/solr/log4j.properties

pushd /var/solr/data
cp -r /var/www/fw-prod/core/solr/configsets .
cp -r /var/www/fw-prod/core/solr/cores .
chown -R solr.solr .
popd

service solr start
sleep 5
# --------------------------------------------------------------------------------------------------

web_serv_start $www_port

pushd tools
./solrindex mode=full optimize=on
popd

# Create a solr specific crontab file for incremental indexing
#-- /etc/cron.d/solr ----------------------------------------------------------------------------------
cat <<EOF > /etc/cron.d/solr
*/15 * * * * www-data /var/www/fw-prod/core/tools/solrjob --mode delta
EOF
#-- /var/www/.bashrc-----------------------------------------------------------------------------------

# Clean out some work files
cd /var/www/fw-prod/core
rm lib/LocalSite.cfg.*
rm working/logs/configure.log

# Tell .git local (non-project) excludes (alternate .gitignore provided by foswiki git_excludes script)
cat <<EOF > /var/www/fw-prod/.gitexclude
*.gz
/core/data/.htpasswd
/core/working/htpasswd.lock
EOF

perl tools/git_excludes.pl
# Hopefully http://localhost:$web_port will now bring up the foswiki Main/WebHome topic
