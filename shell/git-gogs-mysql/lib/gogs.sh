
function gogs_ins {
    local IN_LOG=$LOGPATH/${logpre}_gogs_install.log
    echo
	go_cli_ins	
	[ $? != 0 ] && err_exit "download urfave-cli.tar.gz err"
    [ -f $gogs_inf ] && return
    echo "installing gogs..."
    cd $IN_SRC
    fileurl=$GOGS_URL && filechk
    tar xzvf gogs-${GOGS_VER}.tar.gz
	[ ! -d $IN_DIR ] && mkdir -p $IN_DIR >/dev/null 2>&1
	[ ! -d $IN_DIR/.ssh ] && mkdir -p $IN_DIR/.ssh >/dev/null 2>&1	
	mkdir -p $GOPATH/src/github.com/gogs
	[ -d $GOPATH/src/github.com/gogs ] && rm -rf $GOPATH/src/github.com/gogs/*
	mv gogs-$GOGS_VER $GOPATH/src/github.com/gogs/
	cd $GOPATH/src/github.com/gogs/
	mv gogs-$GOGS_VER gogs
	cd gogs
	echo "gogs building ..."
	make_clean
	#go get -u github.com/urfave/cli
	# mkdir -p ${SOFT_DIR}/gopath/src/github.com/urfave/cli/
	# cd $GOPATH/src/github.com/gogs/gogs
	# git pull --ff-only
	# yum -y install pam-devel
	go build -tags "sqlite pam cert"
	[ $? != 0 ] && err_exit "gogs install err"
	mkdir -p $IN_DIR/gogs-${GOGS_VER}
	ln -sf $IN_DIR/gogs-${GOGS_VER} $IN_DIR/gogs
	cp -R $GOPATH/src/github.com/gogs/gogs/{public,scripts,templates,gogs,LICENSE,README.md,README_ZH.md} $IN_DIR/gogs-${GOGS_VER}
	chown -R git:git $IN_DIR/gogs-${GOGS_VER}
	if [ $OS_RL == 2 ] ; then
		echo "TODO : 非centos, 安装服务, $IN_DIR/gogs-$GOGS_VER"
		exit
        # update-rc.d -f gogs defaults
	else
		cp $IN_DIR/gogs/scripts/systemd/gogs.service  /usr/lib/systemd/system/
		sed -i 's/home\/git/www\/git/g' /usr/lib/systemd/system/gogs.service
		chmod +x /usr/lib/systemd/system/gogs.service
		cp $IN_DIR/gogs/scripts/init/centos/gogs /etc/init.d/gogs
		sed -i 's/home\/git/www\/git/g' /etc/init.d/gogs
		chmod +x /etc/init.d/gogs
        chkconfig --add gogs
		chkconfig --levels 35 gogs on
		service gogs restart
	fi
	[ $? != 0 ] && err_exit "gogs install server err"
	
	mkdir -p $IN_DIR/gogs-${GOGS_VER}/log
	sed -i "s#/home/git/go/src/github.com/gogits/gogs#${IN_DIR}/gogs-${GOGS_VER}#g" $IN_DIR/gogs/scripts/supervisor/gogs
	sed -i "s#/home/git#/www/git#g" $IN_DIR/gogs-${GOGS_VER}/scripts/supervisor/gogs
	sed -i "s#/var/log/gogs#${IN_DIR}/gogs-${GOGS_VER}/log#g" $IN_DIR/gogs-${GOGS_VER}/scripts/supervisor/gogs
	cd $IN_SRC
    touch $gogs_inf	
}
