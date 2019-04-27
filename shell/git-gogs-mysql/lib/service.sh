
function start_srv {
    echo " start server..."
	chkconfig --levels 35 sendmail on
	service sendmail start
	echo "Start sendmail service..."
}