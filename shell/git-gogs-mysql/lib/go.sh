# go install script
function go_ins {
    local IN_LOG=$LOGPATH/${logpre}_go_install.log
    echo

    [ -f $go_inf ] && return
    echo "installing go..."
    cd $IN_SRC
    fileurl=$GO_URL && filechk		
    tar xzvf go-${GO_VER}.tar.gz
    mv go-${GO_VER} $SOFT_DIR
	cd $SOFT_DIR/go-${GO_VER}
	cd src
	make_clean
    [ $? != 0 ] && err_exit "go dir err: ${SOFT_DIR}/go-$GO_VER"
	./all.bash
	[ $? != 0 ] && err_exit "go V${GO_VER} install err."
	ln -s ${SOFT_DIR}/go-${GO_VER} ${SOFT_DIR}/go
	mkdir -p ${SOFT_DIR}/gopath
	echo "export GOROOT=${SOFT_DIR}/go" >> $HOME/.bashrc
	echo "export GOPATH=${SOFT_DIR}/gopath" >> $HOME/.bashrc
	echo "export PATH=\$PATH:\$GOROOT/bin:\$GOPATH/bin" >> $HOME/.bashrc
	source $HOME/.bashrc
    touch $go_inf
}

function go_cli_ins {
    local IN_LOG=$LOGPATH/${logpre}_go_cli_install.log
    echo
	#urfave_
	
    [ -f $go_cli_inf ] && return
    echo "installing go cli..."
    cd $IN_SRC
    fileurl=$GO_CLI_URL && filechk		
    tar xzvf urfave-cli-${GO_CLI_VER}.tar.gz
	mkdir -p $GOPATH/src/github.com/urfave/
    mv cli-${GO_CLI_VER} $GOPATH/src/github.com/urfave/
	cd $GOPATH/src/github.com/urfave/
	mv cli-${GO_CLI_VER} cli
	cd cli
	
    cd $IN_SRC
    touch $go_cli_inf
	
    echo "installing go cli... ok "
}
