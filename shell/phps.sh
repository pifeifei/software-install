#!/bin/bash
# kislong <pifeifei1989@qq.com>
########################################
# use
# ./phps.sh all  # install all version
# ./phps.sh 7.2.17
# 
# configure
#   nginx.conf : fastcgi_pass unix:/tmp/php-{72|73|71|56}-fpm.sock;"
#   这里需要自行修改9000 端口,否则不能多版本共存
#   sed -i "s@php-{72|73|71|56}-fpm.sock@127.0.0.1:9000@" $SOFT_DIR/phps/{72|73|71|56}/etc/php-fpm.d/www.conf
########################################
IN_PWD=$(pwd)
IN_SRC=${IN_PWD}/src
IN_DIR="/www/soft"
SOFT_DIR="/www/soft"
IN_LOG=${IN_PWD}/logs
INF=${IN_PWD}/inf
DL_URL="http://dl.pifeifei.com/files"
# WD_URL="http://www.wdlinux.cn"
[ ! -d $IN_SRC ] && mkdir -p $IN_SRC
[ ! -d $IN_DIR ] && mkdir -p $IN_DIR/phps
[ ! -d $IN_LOG ] && mkdir -p $IN_LOG
[ ! -d $SOFT_DIR/bin ] && mkdir -p $SOFT_DIR/bin
[ ! -d $SOFT_DIR/etc ] && mkdir -p $SOFT_DIR/etc
[ ! -d $SOFT_DIR/phps/vid ] && mkdir -p $SOFT_DIR/phps/vid # 需要开机启动 touch $SOFT_DIR/phps/vid/{72|71|73|56....}
[ ! -d $INF ] && mkdir -p $INF

###
[ $UID != 0 ] && echo -e "\n ERR: You must be root to run the install script.\n\n" && exit

# OS Version detect
# 1:redhat/centos 2:debian/ubuntu
OS_RL=1
grep -qi 'debian\|ubuntu' /etc/issue && OS_RL=2
if [ $OS_RL == 1 ]; then
    R6=0
    R7=0
    grep -q 'release 6' /etc/redhat-release && R6=1
    grep -q 'release 7' /etc/redhat-release && R7=1
fi
X86=0
if uname -m | grep -q 'x86_64'; then
    X86=1
fi
CPUS=`grep processor /proc/cpuinfo | wc -l`
if [ $X86 == 1 ]; then
    ln -sf /usr/lib64/libjpeg.so /usr/lib/
    ln -sf /usr/lib64/libpng.so /usr/lib/
fi


phps="7.2.17 5.4.45 5.5.38 5.6.40 7.0.33 7.1.28 7.3.4"
# php 5.2.x/5.3.x 未测试
if [ $R7 == 0 ];then
	phps="5.2.17 5.3.29 "${phps}
fi

if [ -n "$1" ];then
	[[ "${phps[@]/$1/}" == "${phps[@]}" ]] && exit
	phps=$1
else
	echo -e "\033[31mSelect php version \033[0m"
	echo $phps | tr -s " " "\n"
	echo "all"
	echo "quit"
	read -p "Please enter: " PHPIS
	if [ $PHPIS == "quit" ];then
		exit
	elif [ $PHPIS == "all" ];then
		echo ""	
	else
		phps=$PHPIS
	fi
fi

#
if [ $OS_RL == 1 ];then
	yum install -y gcc gcc-c++ make sudo autoconf libtool-ltdl-devel gd-devel \
       freetype-devel libxml2-devel libjpeg-devel libpng-devel openssl-devel xz \
       curl-devel patch libmcrypt-devel libmhash-devel ncurses-devel bzip2 \
       libcap-devel ntp sysklogd diffutils sendmail iptables unzip cmake wget logrotate \
	re2c bison icu libicu libicu-devel net-tools psmisc vim-enhanced libicu-devel
else
	apt-get install -y gcc g++ make autoconf libltdl-dev libgd2-xpm-dev \
       libfreetype6 libfreetype6-dev libxml2-dev libjpeg-dev libpng12-dev \
       libcurl4-openssl-dev libssl-dev patch libmcrypt-dev libmhash-dev \
       libncurses5-dev  libreadline-dev bzip2 libcap-dev ntpdate \
       diffutils exim4 iptables unzip sudo cmake re2c bison \
       libicu-dev net-tools psmisc xz libzip libzip-devel
fi


pst=0
if [ -n "$2" ];then
	pst=1
fi
grep wdcp /etc/rc.d/rc.local >/dev/null 2>&1
# [ $? == 1 ] &&  echo "/www/wdlinux/wdcp/phps/start.sh" >> /etc/rc.d/rc.local
# [ $? == 1 ] && cat > /etc/rc.d/rc.local<< EOF
# #!/bin/bash
# for v in \`ls /www/soft/phps/vid\`;do /www/soft/phps/\$v/bin/php-fpm start;done
# EOF

function php_ins {
	local IN_LOG=$LOGPATH/php-$1-install.log
	echo
	phpfile="php-${phpv}.tar.gz"
	cd $IN_SRC
	fileurl=$DL_URL/php/$phpfile && filechk
	tar zxvf $phpfile || rm -fr php-${phpv}*
	cd php-${phpv}
	$phpcs
	if [ $phpd -eq 52 ];then
		ln -s ${SOFT_DIR}/mysql/lib/libmysql* /usr/lib/
		ldconfig
    fi
	[ $? != 0 ] && err_exit "php configure err"
	make ZEND_EXTRA_LIBS='-liconv' -j $CPUS
	[ $? != 0 ] && err_exit "php make err"
	make install
	[ $? != 0 ] && err_exit "php install err"
	if [ $phpd -eq 52 ];then
		cp php.ini-recommended $IN_DIR/phps/$phpd/etc/php.ini
		ln -sf $IN_DIR/phps/$phpd/sbin/php-fpm $IN_DIR/phps/$phpd/bin/php-fpm
                sed -i '/nobody/s#<!--##g' $IN_DIR/phps/$phpd/etc/php-fpm.conf
                sed -i '/nobody/s#-->##g' $IN_DIR/phps/$phpd/etc/php-fpm.conf
                sed -i 's/>nobody</>www</' $IN_DIR/phps/$phpd/etc/php-fpm.conf
		sed -i 's/>20</>2</g' $IN_DIR/phps/$phpd/etc/php-fpm.conf
		sed -i 's/>5</>2</g' $IN_DIR/phps/$phpd/etc/php-fpm.conf
		sed -i 's#127.0.0.1:9000#/tmp/php-52-cgi.sock#' $IN_DIR/phps/$phpd/etc/php-fpm.conf
	else
		cp php.ini-production $IN_DIR/phps/$phpd/etc/php.ini
		cp -f sapi/fpm/init.d.php-fpm $IN_DIR/phps/$phpd/bin/php-fpm

		#wget $WD_URL/conf/php/php-fpm.conf -c -O $IN_DIR/phps/$phpd/etc/php-fpm.conf
        #	sed -i 's/{PHPVER}/'$phpd'/g' $IN_DIR/phps/$phpd/etc/php-fpm.conf
		cp $IN_DIR/phps/$phpd/etc/php-fpm.conf.default       $IN_DIR/phps/$phpd/etc/php-fpm.conf
		if [ -f $IN_DIR/phps/$phpd/etc/php-fpm.d/www.conf.default ]; then
			cp $IN_DIR/phps/$phpd/etc/php-fpm.d/www.conf.default $IN_DIR/phps/$phpd/etc/php-fpm.d/www.conf
			fpmwwwfile=$IN_DIR/phps/$phpd/etc/php-fpm.d/www.conf
		else
			fpmwwwfile=$IN_DIR/phps/$phpd/etc/php-fpm.conf
		fi
		sed -i "s@;pid = run/php-fpm.pid@pid = $IN_DIR/phps/${phpd}/var/run/php-fpm.pid@" $IN_DIR/phps/$phpd/etc/php-fpm.conf
		sed -i "s@;error_log = log/php-fpm.log@error_log = $IN_DIR/phps/${phpd}/var/log/php-fpm.log@" $IN_DIR/phps/$phpd/etc/php-fpm.conf
		sed -i "s@;log_level = notice@log_level = notice@" $IN_DIR/phps/$phpd/etc/php-fpm.conf
		sed -i "s@listen = 127.0.0.1:9000@listen = /tmp/php-${phpd}-cgi.sock@" $fpmwwwfile
		sed -i -r "s@^;listen\.backlog = [0-9]+@listen.backlog = -1@" $fpmwwwfile
		sed -i "s@;listen.allowed_clients = 127.0.0.1@listen.allowed_clients = 127.0.0.1@" $fpmwwwfile
		sed -i "s@;listen.owner = www@listen.owner = www@" $fpmwwwfile
		sed -i "s@;listen.group = www@listen.group = www@" $fpmwwwfile
		sed -i -r "s@^;listen.mode = [0-9]+@listen.mode = 0660@" $fpmwwwfile
		sed -i -r "s@^;pm.max_requests = [0-9]+@pm.max_requests = 2000@" $fpmwwwfile
		sed -i -r "s@;request_terminate_timeout = [0-9]+@request_terminate_timeout = 60@" $fpmwwwfile
		# ln -sf ${SOFT_DIR}/phps/$phpd/var/run/php-fpm.pid /tmp/php-$phpd-cgi.sock
		touch $IN_DIR/phps/vid/$phpd
		local ext_dir=`$IN_DIR/phps/$phpd/bin/php-config --extension-dir`
		if [ -f $ext_dir/opcache.so ] ;then
			echo "
[Zend Opcache]
zend_extension = "$ext_dir"/opcache.so
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.validate_timestamps=1
opcache.revalidate_freq=60
opcache.fast_shutdown=1
opcache.enable_file_override=0
" >> $IN_DIR/phps/$phpd/etc/php.ini
		fi
	fi
	[ -f ${SOFT_DIR}/bin/php ]     || ln -s $IN_DIR/phps/$phpd/bin/php     ${SOFT_DIR}/bin/php
	[ -f ${SOFT_DIR}/bin/phpdbg ]  || ln -s $IN_DIR/phps/$phpd/bin/phpdbg  ${SOFT_DIR}/bin/phpdbg
	[ -f ${SOFT_DIR}/bin/php-fpm ] || ln -s $IN_DIR/phps/$phpd/bin/php-fpm ${SOFT_DIR}/bin/php-fpm
	[ -f ${SOFT_DIR}/bin/phpize ]  || ln -s $IN_DIR/phps/$phpd/bin/phpize  ${SOFT_DIR}/bin/phpize
	[ -f ${SOFT_DIR}/bin/phpdbg ]  || ln -s $IN_DIR/phps/$phpd/bin/phpdbg  ${SOFT_DIR}/bin/phpdbg
	[ -f ${SOFT_DIR}/bin/pecl ]    || ln -s $IN_DIR/phps/$phpd/bin/pecl    ${SOFT_DIR}/bin/pecl
	[ -f ${SOFT_DIR}/bin/pear ]    || ln -s $IN_DIR/phps/$phpd/bin/pear    ${SOFT_DIR}/bin/pear
	[ -f ${SOFT_DIR}/etc/php.ini ] || ln -s $IN_DIR/phps/$phpd/etc/php.ini ${SOFT_DIR}/etc/php.ini
	sed -i 's@^short_open_tag = Off@short_open_tag = On@' $IN_DIR/phps/$phpd/etc/php.ini
	sed -i 's@^;date.timezone.*@date.timezone = Asia/Shanghai@' $IN_DIR/phps/$phpd/etc/php.ini
        sed -i 's@^post_max_size = 8M@post_max_size = 30M@g' $IN_DIR/phps/$phpd/etc/php.ini
        sed -i 's@^upload_max_filesize = 2M@upload_max_filesize = 30M@g' $IN_DIR/phps/$phpd/etc/php.ini
	chmod 755 $IN_DIR/phps/$phpd/bin/php-fpm
	if [ $pst == 1 ];then
		$IN_DIR/phps/$phpd/bin/php-fpm start
	fi
	cd $IN_SRC
	rm -fr php-${phpv}
}

function libzip {
	yum remove libzip libzip-devel -y
	fileurl=$DL_URL/other/libzip-1.2.0.tar.gz && filechk
	tar zxvf libzip-1.2.0.tar.gz
	cd libzip-1.2.0
	./configure --prefix=/usr
	make
	[ $? != 0 ] && exit
	make install
	[ -f /usr/lib/libzip/include/zipconf.h ] && ln -s /usr/lib/libzip/include/zipconf.h /usr/include/
	ldconfig
}

function filechk {
    [ -s "${fileurl##*/}" ] || wget -nc --tries=6 --no-check-certificate $fileurl
    if [ ! -e "${fileurl##*/}" ];then
        echo "${fileurl##*/} download failed"
        kill -9 $$
    fi
}

function err_exit {
    echo
    echo
    uname -m
    [ -f /etc/redhat-release ] && cat /etc/redhat-release
    echo -e "\033[31m----Install Error: $phpv -----------\033[0m"
    echo
    echo -e "\033[0m"
    echo
    exit
}


for phpv in $phps; do
	phpfile="php-${phpv}.tar.gz"
	#url="http://dl.wdlinux.cn/files/php/${phpfile}"
	phpd=${phpv:0:1}${phpv:2:1}
	if [ -f $INF/$phpd".txt" ];then
		echo ${phpv}" is Installed"
		continue
	fi
	phpcs="./configure --prefix=${IN_DIR}/phps/"${phpd}" --with-config-file-path=${IN_DIR}/phps/"${phpd}"/etc --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl=/usr --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --disable-fileinfo --enable-intl"
	if [ $phpd -gt 54 ];then
		phpcs=$phpcs" --enable-opcache"
    fi
	if [ $phpd -eq 52 ];then
		phpcs="./configure --prefix=$IN_DIR/phps/"${phpd}" --with-config-file-path=$IN_DIR/phps/"${phpd}"/etc --with-mysql=${SOFT_DIR}/mysql --with-iconv=/usr --with-mysqli=${SOFT_DIR}/mysql/bin/mysql_config --with-pdo-mysql=${SOFT_DIR}/mysql --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-discard-path --enable-inline-optimization --with-curl --enable-mbregex --enable-mbstring --with-mcrypt=/usr --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-ftp --enable-bcmath --enable-exif --enable-sockets --enable-zip --enable-fastcgi --enable-fpm --with-fpm-conf=$IN_DIR/phps/"${phpd}"/etc/php-fpm.conf --with-iconv-dir=/usr"
	fi
	if [ $phpd -ge 73 ];then
		libzip
	fi
	php_ins
	touch $INF/$phpd".txt"
	echo
	echo $phpv" install complete"
done

    echo
    echo
    echo -e "      \033[31mconfigurations, phps install is complete"
	echo -e "      nginx.conf : fastcgi_pass unix:/tmp/php-{72|73|71|56}-fpm.sock;"
    echo -e "      more infomation please visit http://www.pifeifei.com/\033[0m"
    echo

