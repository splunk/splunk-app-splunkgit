
#Global variables
SPLUNK=$SPLUNK_HOME/bin/splunk
SCRIPT_HOME=$(dirname $0)
APP_HOME=`$SPLUNK cmd ./$SCRIPT_HOME/app_home.sh`
APP_NAME=`echo $APP_HOME | sed 's/.*\///'`

# Splunk variables
username_password_script="$SPLUNK cmd python $SCRIPT_HOME/print_splunk_user_and_password.py"
SPLUNK_USERNAME=`$username_password_script | cut -d ':' -f 1`
SPLUNK_PASSWORD=`$username_password_script | cut -d ':' -f 2`

