#!/bin/bash
# kislong <pifeifei1989@qq.com>
########################################
# use (为指定php版本安装swooole)
# ./phps.sh all  # install all version
# ./phps.sh 7.2.17
# swoole v1.x    php-v5.3.10 or later
# swoole v2.0.x  php-v7.0.0  or later
# swoole v2.x    php-v7.0.0  or later
# swoole v4.x    php-v7.1.0  or later
########################################
IN_PWD=$(pwd)
IN_SRC=${IN_PWD}/src
IN_DIR="/www/soft"
SOFT_DIR="/www/soft"
IN_LOG=${IN_PWD}/logs
INF=${IN_PWD}/inf
DL_URL="http://dl.pifeifei.com/files/swoole-php"
[ ! -d $IN_SRC ] && mkdir -p $IN_SRC
[ ! -d $IN_DIR ] && mkdir -p $IN_DIR/phps
[ ! -d $IN_LOG ] && mkdir -p $IN_LOG
[ ! -d $INF ] && mkdir -p $INF

###
[ $UID != 0 ] && echo -e "\n ERR: You must be root to run the install script.\n\n" && exit

#
# OS Version detect
# 1:redhat/centos 2:debian/ubuntu
OS_RL=1
grep -qi 'debian\|ubuntu' /etc/issue && OS_RL=2
if [ $OS_RL == 1 ]; then
    R6=0
    R7=0
    grep -q 'release 6' /etc/redhat-release && R6=1
    grep -q 'release 7' /etc/redhat-release && R7=1 && iptables="iptables-services"
fi
X86=0
if uname -m | grep -q 'x86_64'; then
    X86=1
fi
CPUS=`grep processor /proc/cpuinfo | wc -l`

swoole110="1.10.5"
swoole200="2.0.12"
swoole202="2.2.0"
swoole403="4.3.3"
phps="7.2.17 5.4.45 5.5.38 5.6.40 7.0.33 7.1.28 7.3.4"
if [ $R7 == 0 ];then
	phps="5.3.29 "${phps}
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
	yum install -y hiredis-devel libnghttp2-devel
else
	apt-get install -y libhiredis-dev 
fi

function swoole_ins {
	local IN_LOG=$LOGPATH/swoole${swoolev}-install.log
	echo
	swoolefile="swoole-${swoolev}.tar.gz"
	cd $IN_SRC
	fileurl=$DL_URL/$swoolefile && filechk
	tar zxvf $swoolefile
	cd swoole-${swoolev}
    ${SOFT_DIR}/phps/$phpd/bin/phpize	
	[ $? != 0 ] && err_exit "phpize err"
	#./configure --with-php-config=$IN_DIR/phps/$phpd/bin/php-config
	./configure --with-php-config=$IN_DIR/phps/$phpd/bin/php-config --enable-sockets \
		--enable-openssl  --enable-http2 --enable-swoole --enable-mysqlnd
	#  --enable-coroutine-postgresql --enable-async-redis --enable-async-httpclient 
	[ $? != 0 ] && err_exit "swoole configure err"
	make clean
	make -j $CPUS
	[ $? != 0 ] && err_exit "swoole make err"
	make install
	[ $? != 0 ] && err_exit "swoole make install err"
	
	# [ ! -d $IN_DIR/phps/$phpd/ext ] && mkdir -p $IN_DIR/phps/$phpd/ext
	local ext_dir=`$IN_DIR/phps/$phpd/bin/php-config --extension-dir`
	# cp modules/swoole.so $ext_dir
	# chmod +x $IN_DIR/phps/$phpd/ext/swoole.so
	echo "
[swoole]
extension=swoole
swoole.enable_coroutine=On
swoole.aio_thread_num=4
swoole.display_errors=On
swoole.unixsock_buffer_size=8388608
swoole.socket_buffer_size=8388608
swoole.fast_serialize=On
swoole.use_shortname=On
" >> $IN_DIR/phps/$phpd/etc/php.ini
	[ $phpd -ge 72 ] && sed -i "s/^extension=swoole$/extension=swoole.so/g" $IN_DIR/phps/$phpd/etc/php.ini
	cd $IN_SRC
	rm -fr swoole-${phpv}
}

function filechk {
    [ -s "${fileurl##*/}" ] || wget -nc $fileurl
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
	phpd=${phpv:0:1}${phpv:2:1}
    if [ ! -d $IN_DIR/phps/$phpd ];then
		continue
	fi
	if [ $phpd -le 52 ];then
		continue
	fi
	if [ $phpd -ge 71 ] ; then
		swoolev=$swoole403
	elif [ $phpd -ge 70 ] ; then
		swoolev=$swoole202
	elif [ $phpd -ge 55 ] ; then
		swoolev=$swoole200
	else
		swoolev=$swoole110
	fi
	[ $? != 0 ] && err_exit "swoole select version err"
	swoole_ins
	# php_ins
	echo
	echo $phpv" opcache install complete"
done

    echo
    echo
    echo -e "      \033[31mconfigurations, swoole install is complete"
    echo -e "      more infomation please visit http://www.pifeifei.com/\033[0m"
    echo

