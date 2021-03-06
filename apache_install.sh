# Apache + fastcgi

web_serv_start() {
    service apache2 restart
}

web_serv_install() {
www_port=$1

cat <<"EOF" >> /etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu trusty multiverse
deb http://archive.ubuntu.com/ubuntu trusty-updates multiverse
deb http://security.ubuntu.com/ubuntu trusty-security multiverse
EOF

aptitude update
aptitude -y install apache2 libapache2-mod-fastcgi
a2enmod rewrite 
service apache2 stop

rm /etc/apache2/sites-available/000-default.conf
rm /etc/apache2/sites-available/default-ssl.conf

# start file 000-default.conf
cat <<"EOF" > /etc/apache2/sites-available/fw-prod.conf
# Autogenerated httpd.conf file for Foswiki.
# Generated at http://foswiki.org/Support/ApacheConfigGenerator?vhost=;port=;dir=/var/www/fw-prod/core;symlink=on;pathurl=/;shorterurls=enabled;engine=FastCGI;fastcgimodule=fastcgi;fcgidreqlen=;apver=2;confighost=;configip=;configuser=;loginmanager=Template;htpath=;errordocument=UserRegistration;errorcustom=;phpinstalled=None;blockpubhtml=;blocktrashpub=;controlattach=;blockspiders=;foswikiversion=1.2;apacheversion=2.4;timeout=;ssl=;sslcert=/etc/ssl/apache2/yourservercert.pem;sslchain=/etc/ssl/apache2/sub.class1.server.ca.pem;sslkey=/etc/ssl/apache2/yourservercertkey.pem

ServerName localhost

# For Foswiki version 2.0,  Apache 2.4

# The Alias defines a url that points to the root of the Foswiki installation.
# The first parameter will be part of the URL to your installation e.g.
# http://my.co.uk/foswiki/bin/view/...
# The second parameter must point to the physical path on your disc.

Alias /bin/configure "/var/www/fw-prod/core/bin/configure"
Alias /bin "/var/www/fw-prod/core/bin/foswiki.fcgi"

# The following Alias is used to access files in the pub directory (attachments etc)
# It must come _after_ the ScriptAlias.
# If short URLs are enabled, and any other local directories or files need to be accessed directly, they
# must also be specified in an Alias statement, and must not conflict with a web name.

Alias /pub "/var/www/fw-prod/core/pub"
Alias /robots.txt "/var/www/fw-prod/core/robots.txt"

#  Rewriting is required for Short URLs, and Attachment redirecting to viewfile
RewriteEngine    on
#RewriteLog "/var/log/apache/rewrite.log"
#RewriteLogLevel 0

# short urls
Alias / "/var/www/fw-prod/core/bin/foswiki.fcgi/"
RewriteRule ^/+bin/+view/+(.*) /$1 [L,NE,R]
RewriteRule ^/+bin/+view$ / [L,NE,R]

# This enables access to the documents in the Foswiki root directory

<Directory "/var/www/fw-prod/core">
    <RequireAll>
        Require all granted
        Require not env blockAccess
    </RequireAll>
</Directory>

<IfModule mod_fastcgi.c>
    # Commenting the next setting makes foswiki to be a dynamic server, loaded on demand.
    # Adjust the number of servers to your needs
    FastCgiServer "/var/www/fw-prod/core/bin/foswiki.fcgi" -processes 3

    # Running an external server on the same machine:
    #FastCgiExternalServer "/var/www/fw-prod/core/bin/foswiki.fcgi" -socket /path/to/foswiki.sock

    # Or at another machine:
    #FastCgiExternalServer "/var/www/fw-prod/core/bin/foswiki.fcgi" -host example.com:8080

    # Refer to details at http://www.fastcgi.com/mod_fastcgi/docs/mod_fastcgi.html
</IfModule>

# This specifies the options on the Foswiki scripts directory. The ExecCGI
# and SetHandler tell apache that it contains scripts. "Allow from all"
# lets any IP address access this URL.
# Note:  If you use SELinux, you also have to "Allow httpd cgi support" in your SELinux policies

<Directory "/var/www/fw-prod/core/bin">
    AllowOverride None

    <RequireAll>
        Require all granted
        Require not env blockAccess
    </RequireAll>

    Options +ExecCGI  +FollowSymLinks
    SetHandler cgi-script
    <Files "foswiki.fcgi">
        SetHandler fastcgi-script
    </Files>

    # Password file for Foswiki users
    AuthUserFile "/var/www/fw-prod/core/data/.htpasswd"
    AuthName 'Enter your WikiName: (First name and last name, no space, no dots, capitalized, e.g. JohnSmith). Cancel to register if you do not have one.'
    AuthType Basic

    # File to return on access control error (e.g. wrong password)
    ErrorDocument 401 /System/UserRegistration

</Directory>

# This sets the options on the pub directory, which contains attachments and
# other files like CSS stylesheets and icons. AllowOverride None stops a
# user installing a .htaccess file that overrides these options.
# Note that files in pub are *not* protected by Foswiki Access Controls,
# so if you want to control access to files attached to topics you need to
# block access to the specific directories same way as the ApacheConfigGenerator
# blocks access to the pub directory of the Trash web
<Directory "/var/www/fw-prod/core/pub">
    Options None
    Options +FollowSymLinks
    AllowOverride None

    <RequireAll>
        Require all granted
        Require not env blockAccess
    </RequireAll>
    ErrorDocument 404 /bin/viewfile

   # This line will redefine the mime type for the most common types of scripts
    AddType text/plain .shtml .php .php3 .phtml .phtm .pl .py .cgi
   #
   # add an Expires header that is sufficiently in the future that the browser does not even ask if its uptodate
   # reducing the load on the server significantly
   # IF you can, you should enable this - it _will_ improve your Foswiki experience, even if you set it to under one day.
   # you may need to enable expires_module in your main apache config
   #LoadModule expires_module libexec/httpd/mod_expires.so
   #AddModule mod_expires.c
   #<ifmodule mod_expires.c>
   #  <filesmatch "\.(jpe?g|gif|png|css(\.gz)?|js(\.gz)?|ico)$">
   #       ExpiresActive on
   #       ExpiresDefault "access plus 11 days"
   #   </filesmatch>
   #</ifmodule>
   #
   # Serve pre-compressed versions of .js and .css files, if they exist
   # Some browsers do not handle this correctly, which is why it is disabled by default
   # <FilesMatch "\.(js|css)$">
   #         RewriteEngine on
   #         RewriteCond %{HTTP:Accept-encoding} gzip
   #         RewriteCond %{REQUEST_FILENAME}.gz -f
   #         RewriteRule ^(.*)$ %{REQUEST_URI}.gz [L,QSA]
   # </FilesMatch>
   # <FilesMatch "\.(js|css)\?.*$">
   #         RewriteEngine on
   #         RewriteCond %{HTTP:Accept-encoding} gzip
   #         RewriteCond %{REQUEST_FILENAME}.gz -f
   #         RewriteRule ^([^?]*)\?(.*)$ $1.gz?$2 [L]
   # </FilesMatch>
   # <FilesMatch "\.js\.gz(\?.*)?$">
   #         AddEncoding x-gzip .gz
   #         AddType application/x-javascript .gz
   # </FilesMatch>
   # <FilesMatch "\.css\.gz(\?.*)?$">
   #         AddEncoding x-gzip .gz
   #         AddType text/css .gz
   # </FilesMatch>

</Directory>

# Security note: All other directories should be set so
# that they are *not* visible as URLs, so we set them as =deny from all=.
<Directory "/var/www/fw-prod/core/data">
    Require all denied
</Directory>

<Directory "/var/www/fw-prod/core/templates">
    Require all denied
</Directory>

<Directory "/var/www/fw-prod/core/lib">
    Require all denied
</Directory>

<Directory "/var/www/fw-prod/core/locale">
    Require all denied
</Directory>

<Directory "/var/www/fw-prod/core/tools">
    Require all denied
</Directory>

<Directory "/var/www/fw-prod/core/working">
    Require all denied
</Directory>

# We set an environment variable called blockAccess.
#
# Setting a BrowserMatchNoCase to ^$ is important. It prevents Foswiki from
# including its own topics as URLs and also prevents other Foswikis from
# doing the same. This is important to prevent the most obvious
# Denial of Service attacks.
#
# You can expand this by adding more BrowserMatchNoCase statements to
# block evil browser agents trying to crawl your Foswiki
#
# Example:
# BrowserMatchNoCase ^SiteSucker blockAccess
# BrowserMatchNoCase ^$ blockAccess

BrowserMatchNoCase ^$ blockAccess

EOF
# end file fw-prod.conf

# Enable site and restart server
a2dissite 000-default.conf
a2ensite fw-prod

} # web_serv_install()
