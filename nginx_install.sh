# Nginx with fastcgi

web_serv_start() {
    service nginx start
    service fw-prod start
    update-rc.d fw-prod defaults
}

web_serv_install() {
www_port=$1

apt-get install -y nginx

#-- fw-prod.conf ----------------------------------------------------------------------------------------
cat <<EOF > /etc/nginx/sites-available/fw-prod.conf
server {
    server_name  localhost:$www_port;
EOF

# Append the rest without shell $vars, so we do not need any escapes
cat <<"EOF" >> /etc/nginx/sites-available/fw-prod.conf

    error_log /var/log/nginx/fw-prod.log debug;
    set $fw_root "/var/www/fw-prod/core";
    root $fw_root;

    location /pub/ {
        try_files $uri =404;
        limit_except GET POST { deny all; }
    }
    location / {
        deny all;
    }
    location = / {
           gzip off;
           include fastcgi_params;
           fastcgi_pass             unix:/var/run/www/fw-prod.sock;
           fastcgi_split_path_info  (/.*+)(/.*+);
           fastcgi_param            SCRIPT_FILENAME $fw_root/bin/view;
           fastcgi_param            PATH_INFO       $fastcgi_script_name$fastcgi_path_info;
           fastcgi_param            SCRIPT_NAME     view;
    }
    location ~ ^/[A-Z][A-Za-z0-9]*?/? {
           gzip off;
           include fastcgi_params;
           fastcgi_pass             unix:/var/run/www/fw-prod.sock;
           fastcgi_split_path_info  (/.*+)(/.*+);
           fastcgi_param            SCRIPT_FILENAME $fw_root/bin/view;
           fastcgi_param            PATH_INFO       $fastcgi_script_name$fastcgi_path_info;
           fastcgi_param            SCRIPT_NAME     view;
    }
    location ~ ^/(?!pub\/)([a-z]++)(\/|\?|\;|\&|\#|$) {
           gzip off;
           include fastcgi_params;
           fastcgi_pass             unix:/var/run/www/fw-prod.sock;
           fastcgi_split_path_info  (/\w+)(.*);
           fastcgi_param            SCRIPT_FILENAME $fw_root/bin$fastcgi_script_name;
           fastcgi_param            PATH_INFO       $fastcgi_path_info;
           fastcgi_param            SCRIPT_NAME     $fastcgi_script_name;
    }

    # if ($http_user_agent ~ ^SiteSucker|^iGetter|^larbin|^LeechGet|^RealDownload|^Teleport|^Webwhacker|^WebDevil|^Webzip|^Attache|^SiteSnagger|^WX_mail|^EmailCollecto$
    #     rewrite .* /404.html break;
    # }
}
EOF
#-- fw-prod.conf ----------------------------------------------------------------------------------------


#-- init.d/fw-prod --------------------------------------------------------------------------------------
cat <<"EOF" > /etc/init.d/fw-prod
#!/bin/sh
### BEGIN INIT INFO
# Provides:          fw-prod
# Required-Start:    $syslog $remote_fs $network
# Required-Stop:     $syslog $remote_fs $network
# Should-Start:      fam
# Should-Stop:       fam
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start the Foswiki backend server.
### END INIT INFO

DESC="Foswiki Production Connector"
NAME=fw-prod

PATH=/sbin:/bin:/usr/sbin:/usr/bin
USER=www-data
GRPOUP=www-data

FOSWIKI_ROOT=/var/www/fw-prod/core

mkdir -p /var/run/www
chown www-data:www-data /var/run/www

FOSWIKI_FCGI=foswiki.fcgi
FOSWIKI_BIND=/var/run/www/$NAME.sock
FOSWIKI_CHILDREN=1
FOSWIKI_PIDFILE=/var/run/www/$NAME.pid
FOSWIKI_TRACE=0

# Include defaults if available
if [ -f /etc/default/$NAME ] ; then
    . /etc/default/$NAME
fi

FOSWIKI_DAEMON=$FOSWIKI_ROOT/bin/$FOSWIKI_FCGI
FOSWIKI_DAEMON_OPTS="-n $FOSWIKI_CHILDREN -l $FOSWIKI_BIND -p $FOSWIKI_PIDFILE -d"

start() {
        log_daemon_msg "Starting $DESC" $NAME
        :> $FOSWIKI_PIDFILE
        echo PIDi=$$
        chown $USER:$GROUP $FOSWIKI_PIDFILE
        chmod 777 $FOSWIKI_PIDFILE
        if ! start-stop-daemon --start --oknodo --quiet \
            --chuid $USER:$GROUP \
            --chdir $FOSWIKI_ROOT/bin \
            --pidfile $FOSWIKI_PIDFILE -m \
            --exec $FOSWIKI_DAEMON -- $FOSWIKI_DAEMON_OPTS
        then
            log_end_msg 1
        else
            log_end_msg 0
        fi
}

stop() {
        log_daemon_msg "Stopping $DESC" $NAME
        if start-stop-daemon --stop --retry 30 --oknodo --quiet --pidfile $FOSWIKI_PIDFILE
        then
            rm -f $FOSWIKI_PIDFILE
            log_end_msg 0
        else
            log_end_msg 1
        fi
}

reload() {
        log_daemon_msg "Reloading $DESC" $NAME
        if start-stop-daemon --stop --signal HUP --oknodo --quiet --pidfile $FOSWIKI_PIDFILE
        then
            log_end_msg 0
        else
            log_end_msg 1
        fi
}

status() {
        status_of_proc -p "$FOSWIKI_PIDFILE" "$FOSWIKI_DAEMON" $NAME
}

. /lib/lsb/init-functions

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  reload)
    reload
    ;;
  restart)
    stop
    start
    ;;
  status)
    status
    ;;
  *)
    echo "Usage: $NAME {start|stop|restart|reload|status}"
    exit 1
    ;;
esac
EOF
#-- init.d/fw-prod --------------------------------------------------------------------------------------

chmod 755 /etc/init.d/fw-prod

service nginx stop

chown www-data:www-data /etc/nginx/sites-available/fw-prod.conf
mkdir /var/log/www
touch /var/log/www/fw-prod.log
chown www-data:www-data /var/log/www
chown www-data:www-data /var/log/www/fw-prod.log

rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/fw-prod.conf /etc/nginx/sites-enabled/fw-prod.conf

} # web_serv_install()
