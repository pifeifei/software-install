# mysql 5.7 install function
function mysql_ins {
    local IN_LOG=$LOGPATH/${logpre}_mysql_install.log
    echo
    [ -f $mysql_inf ] && return
    echo "installing mysql,this may take a few minutes,hold on plz..."
    cd $IN_SRC
    fileurl=$MYS_URL && filechk
    tar zvxf mysql-boost-$MYS_VER.tar.gz
    cd mysql-$MYS_VER/
    make_clean
    echo "configure in progress ..."
    cmake . -DCMAKE_INSTALL_PREFIX=$SOFT_DIR/mysql-$MYS_VER \
    -DMYSQL_DATADIR=$SOFT_DIR/mysql-$MYS_VER/data \
    -DDOWNLOAD_BOOST=1 \
    -DWITH_BOOST=boost/boost_1_59_0/ \
    -DSYSCONFDIR=/www/wdlinux/etc \
    -DWITH_INNOBASE_STORAGE_ENGINE=1 \
    -DWITH_PARTITION_STORAGE_ENGINE=1 \
    -DWITH_FEDERATED_STORAGE_ENGINE=1 \
    -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
    -DWITH_MYISAM_STORAGE_ENGINE=1 \
    -DWITH_EMBEDDED_SERVER=1 \
    -DENABLE_DTRACE=0 \
    -DENABLED_LOCAL_INFILE=1 \
    -DDEFAULT_CHARSET=utf8mb4 \
    -DDEFAULT_COLLATION=utf8mb4_general_ci \
    -DEXTRA_CHARSETS=all
    [ $? != 0 ] && err_exit "mysql configure err"
    echo "make in progress ..."
    make -j $CPUS
    [ $? != 0 ] && err_exit "mysql make err"
    echo "make install in progress ..."
    make install 
    [ $? != 0 ] && err_exit "mysql install err"
	[ -f $SOFT_DIR/mysql ] && rm -f $SOFT_DIR/mysql
    ln -sf $SOFT_DIR/mysql-$MYS_VER $SOFT_DIR/mysql
    [ -f /etc/my.cnf ] && mv /etc/my.cnf /etc/my.cnf.old
	[ ! -d $SOFT_DIR/init.d/ ] && mkdir -p $SOFT_DIR/init.d/
    cp support-files/mysql.server $SOFT_DIR/init.d/mysqld
	[ ! -d $SOFT_DIR/etc/ ] && mkdir -p $SOFT_DIR/etc/
    file_cp my.cnf $SOFT_DIR/etc/my.cnf
    ln -sf $SOFT_DIR/etc/my.cnf /etc/my.cnf
    $SOFT_DIR/mysql-$MYS_VER/bin/mysqld --initialize-insecure --user=mysql --basedir=$SOFT_DIR/mysql-$MYS_VER --datadir=$SOFT_DIR/mysql-$MYS_VER/data
	[ $? == 0 ] || rm -fr $SOFT_DIR/mysql-$MYS_VER/data && $SOFT_DIR/mysql-$MYS_VER/bin/mysqld --initialize-insecure --user=mysql --basedir=$SOFT_DIR/mysql-$MYS_VER --datadir=$SOFT_DIR/mysql-$MYS_VER/data
	chown -R mysql.mysql $SOFT_DIR/mysql/data
    chmod 755 $SOFT_DIR/init.d/mysqld
    ln -sf $SOFT_DIR/init.d/mysqld /etc/init.d/mysqld
    if [ $OS_RL == 2 ]; then
        update-rc.d -f mysqld defaults
    else
        chkconfig --add mysqld
        chkconfig --level 35 mysqld on
    fi
    ln -sf $SOFT_DIR/mysql/bin/mysql /bin/mysql
    mkdir -p /var/lib/mysql
    service mysqld start
    echo "PATH=\$PATH:$SOFT_DIR/mysql/bin" > /etc/profile.d/mysql.sh
    echo "$SOFT_DIR/mysql" > /etc/ld.so.conf.d/mysql-wdl.conf
    ldconfig 
    $SOFT_DIR/mysql-$MYS_VER/bin/mysql -e "grant all privileges on *.* to root@'127.0.0.1' identified by \"pifeifei.com\" with grant option;"
    $SOFT_DIR/mysql-$MYS_VER/bin/mysql -e "grant all privileges on *.* to root@'localhost' identified by \"pifeifei.com\" with grant option;"
    [ -d /var/lib/mysql ] && ln -sf /tmp/mysql.sock /var/lib/mysql/
    cd $IN_SRC
    rm -fr mysql-$MYS_VER
    touch $mysql_inf
}