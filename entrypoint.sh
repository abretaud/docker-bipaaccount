#!/bin/bash
set -e

function run_scripts () {
	SCRIPTS_DIR="/scripts/$1.d"
	SCRIPT_FILES_PATTERN="^${SCRIPTS_DIR}/[0-9][0-9][a-zA-Z0-9_-]+$"
	SCRIPTS=$(find "$SCRIPTS_DIR" -type f -uid 0 -executable -regex "$SCRIPT_FILES_PATTERN" | sort)
	if [ -n "$SCRIPTS" ] ; then
		echo "=>> $1-scripts:"
	    for script in $SCRIPTS ; do
	        echo "=> $script"
			. "$script"
	    done
	fi
}

### auto-configure database from environment-variables
: ${MAILER_HOST:='127.0.0.1'}
: ${MAILER_PORT:='25'}
: ${MAILER_USER:='null'}
: ${MAILER_PASS:='null'}

export SECRET=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1`

: ${APACHE_RUN_USER:='www-data'}
: ${APACHE_RUN_GROUP:='www-data'}

###

run_scripts pre-launch

exec apache2-foreground

exit 1
