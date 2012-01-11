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

# This script polls a git remote repo for changes and prints the results to standart out in a format splunk easily can read.
# Author: Petter Eriksson, Emre Berge Ergenekon

#Global variables
SCRIPT_HOME=$(dirname $0)
APP_HOME=`splunk cmd ./$SCRIPT_HOME/app_home.sh`
APP_NAME=`echo $APP_HOME | sed 's/.*\///'`

# Splunk authentication
username_password_script="splunk cmd python $SCRIPT_HOME/print_splunk_user_and_password.py"
SPLUNK_USERNAME=`$username_password_script | grep -oP '^[^:]+'`
SPLUNK_PASSWORD=`$username_password_script | grep -oP '(?<=:)(.*)'`

#Initializing
GIT_REPO=
GIT_REPO_FOLDER=
GIT_REPOS_HOME=
chosen_repository=

#XML writing for a view that views all repositories
xml_file=$APP_HOME/local/data/ui/views/multi_repositories.xml

main ()
{
setup_xml
for repository in `splunk cmd python $SCRIPT_HOME/splunkgit_settings.py`
do
  echo "fetching git repo data for repository: $repository" 1>&2
  GIT_REPO=$repository
  GIT_REPO_FOLDER=`echo $GIT_REPO | sed 's/.*\///'`
  GIT_REPOS_HOME=$APP_HOME/git-repositories
  chosen_repository=$GIT_REPOS_HOME/$GIT_REPO_FOLDER

  if [ "$GIT_REPO" = "" ]; then
    echo "Could not find configured git repository. Have you configured splunkgit.conf? Read README.md for more information." 1>&2
  else
    if [ -d "$chosen_repository" ]; then
      print_hashes_and_git_log_numstat
    else
      echo "repository does not exist!" 1>&2
      fetch_git_repository
    fi
  fi
  write_xml $repository
done
end_xml
}

setup_xml () {
  # Create xml file
  echo "<?xml version='1.0' encoding='utf-8'?>" > $xml_file
  echo "<dashboard>" >> $xml_file
  echo "  <label>Repositories</label>" >> $xml_file
}

# Write multi_repositories_row.txt and replace ---REPOSITORY--- with $1, which should be a repository
write_xml () {
  repository=$1
  cat $APP_HOME/bin/multi_repositories_row.txt | sed "s,---REPOSITORY---,$repository," >> $xml_file
}

end_xml () {
  echo "</dashboard>" >> $xml_file
# Reload views for $APP_NAME (splunkgit)
  curl -s -u $SPLUNK_USERNAME:$SPLUNK_PASSWORD -k https://localhost:8089/servicesNS/nobody/$APP_NAME/data/ui/views/_reload > /dev/null
}

#Not safe to run this method parallel from the same directory, since the $numstat_file is touched, written to and deleted.
#TODO: Figure out a way to remove the $numstat_file logic.
print_hashes_and_git_log_numstat ()
{
  cd $chosen_repository
  git fetch 1>&2
  NUMBER_OF_COMMITS_TO_SKIP=`splunk search "index=splunkgit repository=$GIT_REPO | stats dc(commit_hash) as commitCount" -auth admin:changeme -app $APP_NAME | grep -o -P '[0-9]+'`

#For each commit in the repository do:
#if commit doesn't have edited lines, just print 'time, author_name, author_mail, commit...'
#else
#for each file change in commit do:
#print commit info in front of every file change.
  git log --pretty=format:'[%ci] author_name="%an" author_mail="%ae" commit_hash="%H" parrent_hash="%P" tree_hash="%T"' --numstat --all --no-color --no-renames --no-merges --skip=$NUMBER_OF_COMMITS_TO_SKIP | sed '/^$/d' | awk -F \t -v FIRST_LINE=1 -v REPO="$GIT_REPO" -v RECENT_COMMIT=0 '{IS_COMMIT = match($0, /^\[/); if (IS_COMMIT) { if (RECENT_COMMIT==1) {print COMMIT_INFO } RECENT_COMMIT=1; COMMIT_INFO=$0} else {RECENT_COMMIT=0; print COMMIT_INFO" insertions=\""$1"\" deletions=\""$2"\" path=\""$3"\" file_type=\"---/"$3"---\" repository=\""REPO"\""}}' | perl -pe 's|---.*/(.+?)---|---\.\1---|' | perl -pe 's|---.*\.(.+?)---|\1|'
}

fetch_git_repository ()
{
  error_output=err.out
  mkdir -p $GIT_REPOS_HOME
  git clone --mirror $GIT_REPO $chosen_repository 1>&2
  git_exit_code=$?
  if [[ $git_exit_code == 0 ]]; then
    print_hashes_and_git_log_numstat # try again
  else
    echo "Unable to clone repository: $GIT_REPO" 1>&2
  fi
}

main
