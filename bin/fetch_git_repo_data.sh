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

# Script creates splunk events with each file change for all commits, with insertions and deletions.
# Here's an example with some of the contents of these events: 
# [10-12-23 12:34:56] commit=123adf32fa21 repository=repo path=src/clj/core.clj insertions=3 deletions=1
# Author: Petter Eriksson, Emre Berge Ergenekon

SCRIPT_HOME=$(dirname $0)
source $SCRIPT_HOME/shell_variables.sh

#Initializing
GIT_REPO=
GIT_REPO_FOLDER=
GIT_REPOS_HOME=
chosen_repository=

main ()
{
  $SCRIPT_HOME/git_fetch_repos.sh
for repository in `$SPLUNK cmd python $SCRIPT_HOME/splunkgit_settings.py`
do
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
    fi
  fi
done
}

print_hashes_and_git_log_numstat ()
{
  cd $chosen_repository
  git fetch 1>&2

# Find the last indexed commit.
# If there are no indexed commits, get the first commit of the repository.
  SINCE_COMMIT=""

  HAS_INDEXED_COMMITS=`$SPLUNK search "index=splunkgit repository=$GIT_REPO sourcetype=git_file_change | head 1 | stats count" -auth $SPLUNK_USERNAME:$SPLUNK_PASSWORD -app $APP_NAME | grep -oP '\d+'`
  if [ "$HAS_INDEXED_COMMITS" = "0" ]; then
    FIRST_COMMIT=`git log --all --no-color --no-renames --no-merges --reverse --pretty=format:'%H' | head -n 1`
    SINCE_COMMIT=$FIRST_COMMIT
  else
    LATEST_INDEXED_COMMIT=`$SPLUNK search "index=splunkgit repository=$GIT_REPO sourcetype="git_file_change" | sort 1 - _time | table commit_hash" -auth $SPLUNK_USERNAME:$SPLUNK_PASSWORD -app $APP_NAME | grep -oP '^\w+'`
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
  git log --pretty=format:'[%ci] author_name="%an" author_mail="%ae" commit_hash="%H" parent_hash="%P" tree_hash="%T"' --numstat --all --no-color --no-renames --no-merges --since=$UNIX_TIME_OF_SINCE_COMMIT $SINCE_COMMIT.. |
    sed '/^$/d' |
    awk -F '\t' -v FIRST_LINE=1 -v REPO="$GIT_REPO" -v RECENT_COMMIT=0 '{
      IS_COMMIT = match($0, /^\[/);
      if (IS_COMMIT) {
        if (RECENT_COMMIT==1) {
          print COMMIT_INFO
        }
        RECENT_COMMIT=1;
        COMMIT_INFO=$0
      } else {
        RECENT_COMMIT=0;
        print COMMIT_INFO" insertions=\""$1"\" deletions=\""$2"\" path=\""$3"\" file_type=\"---/"$3"---\" repository=\""REPO"\""
      }
    }' |
    perl -pe 's|---.*/(.+?)---|---\.\1---|' |
    perl -pe 's|---.*\.(.+?)---|\1|'
}

main
