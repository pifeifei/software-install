# git install function
function git_ins { 
    local IN_LOG=$LOGPATH/${logpre}_git_install.log
    echo

    [ -f $git_inf ] && return
    echo "installing git..."
    cd $IN_SRC
    fileurl=$GIT_URL && filechk	
    tar xzvf git-${GIT_VER}.tar.gz
    cd git-$GIT_VER
	make_clean
	if [ $OS_RL == 1 ]; then
		yum update -y nss curl libcurl 
	elif [ $OS_RL == 2 ]; then
		apt-get install -y  nss
	fi
	make_clean
	# make -j $CPUS
	make -j $CPUS CFLAGS=-liconv prefix=${SOFT_DIR}/git-${GIT_VER} all
    [ $? != 0 ] && err_exit "git make err"
    make -j $CPUS CFLAGS=-liconv prefix=${SOFT_DIR}/git-${GIT_VER} install
    [ $? != 0 ] && err_exit "git install err"
	# TODO : 判断是否连接文件, 是的话删除,不是就备份, 这里只做了备份
	[ -d ${SOFT_DIR}/git ] && mv ${SOFT_DIR}/git ${SOFT_DIR}/git_bk_`date +%s`
	SOFT_DIR=/www/soft
	[ ! -d $SOFT_DIR/bin/ ] && mkdir $SOFT_DIR/bin/
	cd $SOFT_DIR
	for i in `find git/bin/ -type f `;do ln -sf ../$i bin/${i##*/} ; done
	#ln -sf ${SOFT_DIR}/git-${GIT_VER} ${SOFT_DIR}/git
	#[ ! -f ${SOFT_DIR}/git/bin/git ]                && ln -sf ${SOFT_DIR}/git/bin/git                /bin/git
	#[ ! -f ${SOFT_DIR}/git/bin/git-cvsserver ]      && ln -sf ${SOFT_DIR}/git/bin/git-cvsserver      /bin/git-cvsserver
	#[ ! -f ${SOFT_DIR}/git/bin/gitk ]               && ln -sf ${SOFT_DIR}/git/bin/gitk               /bin/gitk
	#[ ! -f ${SOFT_DIR}/git/bin/git-receive-pack ]   && ln -sf ${SOFT_DIR}/git/bin/git-receive-pack   /bin/git-receive-pack
	#[ ! -f ${SOFT_DIR}/git/bin/git-shell ]          && ln -sf ${SOFT_DIR}/git/bin/git-shell          /bin/git-shell
	#[ ! -f ${SOFT_DIR}/git/bin/git-upload-archive ] && ln -sf ${SOFT_DIR}/git/bin/git-upload-archive /bin/git-upload-archive
	#[ ! -f ${SOFT_DIR}/git/bin/git-upload-pack ]    && ln -sf ${SOFT_DIR}/git/bin/git-upload-pack    /bin/git-upload-pack
	cd $IN_SRC
    rm -fr git-$GIT_VER
    touch $git_inf
}
