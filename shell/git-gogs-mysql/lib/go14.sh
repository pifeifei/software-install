# go 1.4.3 install script
function go14_ins {
    local IN_LOG=$LOGPATH/${logpre}_go_install.log
    echo

    [ -f $go14_inf ] && return
    echo "installing go 1.4.3..."
    cd $IN_SRC
    fileurl=$GO14_URL && filechk
    tar xzvf go-${GO14_VER}.tar.gz
	mv go-$GO14_VER ${SOFT_DIR}/
	cd ${SOFT_DIR}/go-$GO14_VER
	cd src
	make_clean
	chmod +x ../misc/cgo/testgodefs/*.bash
	chmod +x ../misc/cgo/errors/*.bash
	chmod +x ../misc/cgo/testcdefs/*.bash
	# for i in `find .. -type f -name "*.bash"`;do chmod +x $i;done
	./all.bash
	[ $? != 0 ] && err_exit "go V1.4 install err."
	export GOROOT_BOOTSTRAP="${SOFT_DIR}/go-1.4.3"
    touch $go14_inf
}
