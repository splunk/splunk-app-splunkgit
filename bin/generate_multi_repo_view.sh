#!/bin/bash

# Copyright 2011 Splunk, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Script for generating a view that views all repositories that are configured in splunkgit.conf
# Author: Petter Eriksson

#Global variables
SCRIPT_HOME=$(dirname $0)
SPLUNK=$SPLUNK_HOME/bin/splunk
APP_HOME=`$SPLUNK cmd ./$SCRIPT_HOME/app_home.sh`

# Splunk authentication
username_password_script="$SPLUNK cmd python $SCRIPT_HOME/print_splunk_user_and_password.py"
SPLUNK_USERNAME=`$username_password_script | grep -oP '^[^:]+'`
SPLUNK_PASSWORD=`$username_password_script | grep -oP '(?<=:)(.*)'`

#XML writing for a view that views all repositories
xml_dir=$APP_HOME/local/data/ui/views
xml_file=$xml_dir/multi_repositories.xml

main ()
{
  setup_xml
  for repository in `$SPLUNK cmd python $SCRIPT_HOME/splunkgit_settings.py`
  do
    write_xml $repository
  done
  end_xml
}

setup_xml () {
  # Create xml file
  mkdir -p $xml_dir
  echo "<?xml version='1.0' encoding='utf-8'?>" > $xml_file
  echo "<dashboard>" >> $xml_file
  echo "  <label>Repositories</label>" >> $xml_file
}

# Write multi_repositories_row.txt and replace ---REPOSITORY--- with $1, which should be a repository
write_xml () {
  repository=$1
  repository_simple_name=`echo $repository | sed 's/.*\///' | sed 's,\.git,,'`
  cat $APP_HOME/bin/multi_repositories_row.txt | sed "s,---REPOSITORY---,$repository," | sed "s,---REPOSITORY_SIMPLE_NAME---,$repository_simple_name,"  >> $xml_file
}


end_xml () {
  echo "</dashboard>" >> $xml_file
  # Reload views for $APP_NAME (splunkgit)
  curl -s -u $SPLUNK_USERNAME:$SPLUNK_PASSWORD -k https://localhost:8089/servicesNS/nobody/$APP_NAME/data/ui/views/_reload > /dev/null
}

# Run script
main