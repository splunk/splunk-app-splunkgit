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
SPLUNK=$SPLUNK_HOME/bin/splunk
APP_HOME=`$SPLUNK cmd ./$SCRIPT_HOME/app_home.sh`
APP_NAME=`echo $APP_HOME | sed 's/.*\///'`

#Initializing
GIT_REPO=
GIT_REPO_FOLDER=
GIT_REPOS_HOME=
chosen_repository=

# Splunk variables
username_password_script="$SPLUNK cmd python $SCRIPT_HOME/print_splunk_user_and_password.py"
SPLUNK_USERNAME=`$username_password_script | grep -oP '^[^:]+'`
SPLUNK_PASSWORD=`$username_password_script | grep -oP '(?<=:)(.*)'`

main ()
{
for repository in `$SPLUNK cmd python $SCRIPT_HOME/splunkgit_settings.py`
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
done
}

#Not safe to run this method parallel from the same directory, since the $numstat_file is touched, written to and deleted.
#TODO: Figure out a way to remove the $numstat_file logic.
print_hashes_and_git_log_numstat ()
{
  cd $chosen_repository
  git fetch 1>&2

# Find the last indexed commit.
# If there are no indexed commits, get the first commit of the repository.
  SINCE_COMMIT=""

  commit_messages_search="index=splunkgit repository=$GIT_REPO sourcetype=git_commit_messages | head 1 | stats count"

  HAS_INDEXED_COMMITS=`$SPLUNK search "$commit_messages_search" -auth $SPLUNK_USERNAME:$SPLUNK_PASSWORD -app $APP_NAME | grep -oP '\d+'`
  if [ "$HAS_INDEXED_COMMITS" = "0" ]; then
    FIRST_COMMIT=`git log --all --no-color --no-renames --no-merges --reverse --pretty=format:'%H' | head -n 1`
    SINCE_COMMIT=$FIRST_COMMIT
  else
    LATEST_INDEXED_COMMIT=`$SPLUNK search "index=splunkgit repository=$GIT_REPO sourcetype=git_commit_messages | sort 1 - _time | table commit_hash" -auth $SPLUNK_USERNAME:$SPLUNK_PASSWORD -app $APP_NAME | grep -oP '^\w+'`
    SINCE_COMMIT=$LATEST_INDEXED_COMMIT
  fi

# Get the time of the commit we are logging since.
# Note: We're getting the time, so we can specify the --since flag to git log.
#       Otherwise, we can get commits that were made earlier than we would have wanted.
UNIX_TIME_OF_SINCE_COMMIT=`git log $SINCE_COMMIT -n 1 --pretty=format:'%ct'`

#For each commit in the repository do:
#if commit doesn't have edited lines, just print 'time, author_name, author_mail, commit...'
#else
#for each file change in commit do:
#print commit info in front of every file change.
  git log --pretty=format:"repository=\"$GIT_REPO\" [%ci] commit_hash=%H message=\"%B\"" --all --no-color --no-renames --no-merges --since=$UNIX_TIME_OF_SINCE_COMMIT $SINCE_COMMIT.. |
   sed '/^$/d'
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
