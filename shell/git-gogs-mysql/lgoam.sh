#!/bin/bash
#
# git and gogs Install Script
# Created by kislong QQ:270228163
# Url:http://www.pifeifei.com
# Since 2019.03.16
# linux git gogs/gitlab mysql nginx

. lib/common.conf
. lib/common.sh
. lib/mysql.sh
. lib/libiconv.sh
. lib/git.sh
. lib/go14.sh
. lib/go.sh
. lib/gogs.sh
. lib/service.sh

# make sure source files dir exists.
[ -d $IN_SRC ] || mkdir $IN_SRC
[ -d $LOGPATH ] || mkdir $LOGPATH
[ -d $INF ] || mkdir $INF

if [ "$1" == "un" -o "$1" == "uninstall" ]; then
    # TODO : 
    service gogs stop
    mkdir /www/backup
    bf=$(date +%Y%m%d)
    tar zcf /www/backup/git_$bf.tar.gz /www/git/gogs-repositories
    rm -fr /www/git
    rm -f inf/*.txt
    reboot
    exit
fi

###
###
echo "Select Install
    1 gg (git + gogs)
    2 ggm (git + gogs + mysql)
    3 don't install is now
"
#    1 gg  (git + gogs)
#    2 ggm (git + gogs + mysql)
#    3 gl  (git + GitLab) TODO
#    4 glm (git + GitLab + mysql) TODO

sleep 0.1
read -p "Please Input 1,2,3: " SERVER_ID
if [[ $SERVER_ID == 2 ]]; then
    SERVER="ggm"
elif [[ $SERVER_ID == 1 ]]; then
    SERVER="gg"
else
    exit
fi

# SERVER_ID=1

if [ "$1" == "cus" ];then
###git
echo -e "\033[31m   Select git version \033[0m"
echo "	1 1.9.5
	2 2.21.0"
read -p "   Please Input 1,2: " GIT_ID
[ $GIT_ID == 1 ] && GIT_VER="1.9.5"
[ $GIT_ID == 2 ] && GIT_VER="2.21.0"
echo

###gogs
echo -e "\033[31m   Select gogs version \033[0m"
echo "	1 0.10.18
	2 0.11.86"
read -p "   Please Input 1,2: " GIT_ID
[ $GIT_ID == 1 ] && GIT_VER="0.10.18"
[ $GIT_ID == 2 ] && GIT_VER="0.11.86"
echo
fi

# make sure network connection usable.
ping -c 1 -t 1 dl.pifeifei.com >/dev/null 2>&1
if [[ $? == 2 ]]; then
    echo "nameserver 114.114.114.114
nameserver 202.96.128.68" > /etc/resolv.conf
    echo "dns err"
fi
ping -c 1 -t 1 dl.pifeifei.com >/dev/null 2>&1
if [[ $? == 2 ]]; then
    echo "dns err"
    exit
fi

if [ $OS_RL == 1 ]; then
    sed -i 's/^exclude=/#exclude=/g' /etc/yum.conf
fi


###
if [ $OS_RL == 2 ]; then
    service gogs stop 2>/dev/null
    service mysql stop 2>/dev/null
    apt-get update
    apt-get remove -y git 2>/dev/null
    apt-get -y autoremove
	if [ $SERVER_ID == 2 ]; then
		apt-get remove -y mysql 2>/dev/null
		[ -f /etc/mysql/my.cnf ] && mv /etc/mysql/my.cnf /etc/mysql/my.cnf.lanmpsave
	fi
    yun_apt_ins
else
    rpm -e --nodeps git >/dev/null 2>&1
    [ ! -f $INF/dag.txt ] && rpm --import conf/RPM-GPG-KEY.dag.txt && touch $INF/dag.txt
    [ $R6 == 1 ] && el="el6" || el="el5"
    [ ! -f $INF/gcc.txt ] && yum_apt_ins && touch $INF/gcc.txt
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    ntpdate tiger.sina.com.cn
    hwclock -w
fi

if [ ! -d $IN_DIR ]; then
    mkdir -p $IN_DIR/{etc,init.d}
    mkdir -p $SOFT_DIR/{etc,init.d}
	mkdir -p $SOFT_DIR
    mkdir -p $IN_DIR/gogs-repositories
    if [ $OS_RL == 2 ]; then
        /etc/init.d/apparmor stop >/dev/null 2>&1
        update-rc.d -f apparmor remove >/dev/null 2>&1
        apt-get remove -y apparmor apparmor-utils >/dev/null 2>&1
        ogroup=$(awk -F':' '/x:1000:/ {print $1}' /etc/group)
        [ -n "$ogroup" ] && groupmod -g 1010 $ogroup >/dev/null 2>&1
        ouser=$(awk -F':' '/x:1000:/ {print $1}' /etc/passwd)
        [ -n "$ouser" ] && usermod -u 1010 -g 1010 $ouser >/dev/null 2>&1
        adduser --system --group --home /nonexistent --no-create-home mysql >/dev/null 2>&1
    else
        setenforce 0
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        service gogs stop >/dev/null 2>&1
        #service mysqld stop >/dev/null 2>&1
        chkconfig --level 35 gogs off >/dev/null 2>&1
        #chkconfig --level 35 mysqld off >/dev/null 2>&1
        chkconfig --level 35 sendmail off >/dev/null 2>&1
	ogroup=$(awk -F':' '/x:1000:/ {print $1}' /etc/group)
        [ -n "$ogroup" ] && groupmod -g 1010 $ogroup >/dev/null 2>&1
        ouser=$(awk -F':' '/x:1000:/ {print $1}' /etc/passwd)
        [ -n "$ouser" ] && usermod -u 1010 -g 1010 $ouser >/dev/null 2>&1
        groupadd -g 27 mysql >/dev/null 2>&1
        useradd -g 27 -u 27 -d /dev/null -s /sbin/nologin mysql >/dev/null 2>&1
    fi
    groupadd -g 1100 git >/dev/null 2>&1
    useradd -g 1100 -u 1100 -d /dev/null -s /sbin/nologin git >/dev/null 2>&1
fi

cd $IN_SRC

[ $IN_DIR = "/www/git" ] || IN_DIR_ME=1

###install
geturl
if [ "$SERVER_ID" == 2 ];then
	###mysql
	mysql_ins
fi

libiconv_ins
git_ins
go14_ins
go_ins
gogs_ins
start_srv
gg_in_finsh
cd $IN_PWD
rm -f gg-v1*
