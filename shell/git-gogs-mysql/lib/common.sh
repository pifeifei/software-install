function make_clean {
    if [ $RE_INS == 1 ]; then
        make clean >/dev/null 2>&1
    fi
}

function wget_down {
    if [ $SOFT_DOWN == 1 ]; then
        echo "start down..."
        for i in $*; do
            [ $(wget -c $i) ] && exit
        done
    fi
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
    echo -e "\033[31m----Install Error: $1 -----------\033[0m"
    echo
    echo -e "\033[0m"
    echo
    exit
}

function error {
    echo -e "\033[31m ERROR: $1 \033[0m"
    exit
}

function file_cp {
    #[ -f $2 ] && mv $2 ${2}$(date +%Y%m%d%H)
    cd $IN_PWD/conf
    [ -f $1 ] && cp -f $1 $2
}

function file_cpv {
    cd $IN_PWD/conf
    [ -f $1 ] && cp -f $1 $2
}

function file_rm {
    [ -f $1 ] && rm -f $1
}

function file_bk {
    [ -f $1 ] && mv $1 ${1}_$(date +%Y%m%d%H)
}

function Checkinitd {
    [ -f /etc/init.d/$1 ] && rm -f /etc/init.d/$1
    [ $R7 == 1 ] && cp -f /www/wdlinux/init.d/$1 /etc/init.d/$1 || ln -s /www/wdlinux/init.d/$1 /etc/init.d/$1
	SETPATH=`grep SOFTPATH /etc/bashrc`
	[ ! -s SETPATH ] && echo 'SOFTPATH=/www/soft'>>/etc/bashrc
	[ ! -s SETPATH ] && echo 'PATH=$PATH:$SOFTPATH/bin'>>/etc/bashrc
	source /etc/bashrc
}

function CheckSoftPath {
    # TODO : 添加环境变量
	# SOFTPATH="/www/soft"
	# PATH=$PATH:$SOFTPATH/bin
}

function yum_apt_ins {
	if [ $OS_RL == 1 ];then
		yum install -y gcc gcc-c++ make sudo autoconf openssl-devel \
        curl-devel patch cmake wget expat-devel gettext-devel zlib-devel \
		sendmail pam-devel ntpdate
	else
		apt-get install -y gcc g++ make autoconf \
        libcurl4-openssl-dev libssl-dev libcurl4-gnutls-dev libexpat1-dev \
		gettext libz-dev libssl-dev ntpdate
	fi
}

function gg_in_finsh {
    echo
    echo
    echo
    echo -e "      \033[31mCongratulations ,git,gogs install is complete"
    echo -e "      gogs http://ip:3000"
    echo -e "      more infomation please visit http://www.pifeifei.com/\033[0m"
    echo
	mysql_create_gogs
}

function mysql_create_gogs {
	if [ "$SERVER_ID" == 2 ];then
		gogsuser="gogs_$(expr substr "$(echo $RANDOM | md5sum)" 1 8)"
		gogspass=`< /dev/urandom tr -dc 0-9A-Za-z|head -c ${1:-15};`
		$SOFT_DIR/mysql-$MYS_VER/bin/mysql -uroot -ppifeifei.com -e "create schema ${gogsuser} default character set utf8mb4 collate utf8mb4_general_ci;" >/dev/null 2>&1
		$SOFT_DIR/mysql-$MYS_VER/bin/mysql -uroot -ppifeifei.com -e "create user '${gogsuser}'@'%' identified by '${gogspass}';" >/dev/null 2>&1
		$SOFT_DIR/mysql-$MYS_VER/bin/mysql -uroot -ppifeifei.com -e "grant select,insert,update,delete,create on ${gogsuser}.* to ${gogsuser};" >/dev/null 2>&1
		$SOFT_DIR/mysql-$MYS_VER/bin/mysql -uroot -ppifeifei.com -e "flush  privileges ;" >/dev/null 2>&1
		echo 
		echo -e "    \033[31m mysql database: ${gogsuser} \033[0m"
		echo -e "    \033[31m mysql username: ${gogsuser} \033[0m"
		echo -e "    \033[31m mysql user passwd: ${gogspass} \033[0m"
		echo 
	fi
}