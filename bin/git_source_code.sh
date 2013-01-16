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

# Prints the source code for all the changed files in each commit.
# Takes one argument ($1), which is the file pattern that should be printed to stdout.
# For example: '\.xml$' would only print the xml files that has been changed in the repository.
# This script is disabled in the default/inputs.conf by default.
# Author: Petter Eriksson

SCRIPT_HOME=$(dirname $0)
source $SCRIPT_HOME/shell_variables.sh

# file pattern goes into the first variable.
file_pattern=$1

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
      print_source_code
    else
      echo "repository does not exist!" 1>&2
    fi
  fi
done
}

print_source_code ()
{
  cd $chosen_repository
  git fetch 1>&2

# Clone the repository with files instead of just bare/mirror
  cd ..
  repo_with_files=$chosen_repository-with-files
  if [ ! -d "$repo_with_files" ]; then
    git clone $chosen_repository $repo_with_files 1>&2
  fi
  cd $repo_with_files
  git reset --hard master 1>&2
  git pull $chosen_repository master 1>&2

# Find the last indexed commit.
# If there are no indexed commits, get the first commit of the repository.
  SINCE_COMMIT=""

  commit_messages_search="index=splunkgit repository=$GIT_REPO sourcetype=git_source_code | head 1 | stats count"

  HAS_INDEXED_COMMITS=`$SPLUNK search "$commit_messages_search" -auth $SPLUNK_USERNAME:$SPLUNK_PASSWORD -app $APP_NAME | egrep -o '[0-9]+'`
  if [ "$HAS_INDEXED_COMMITS" = "0" ]; then
    FIRST_COMMIT=`git log --all --no-color --no-renames --no-merges --reverse --pretty=format:'%H' | head -n 1`
    SINCE_COMMIT=$FIRST_COMMIT
  else
    LATEST_INDEXED_COMMIT=`$SPLUNK search "index=splunkgit repository=$GIT_REPO sourcetype=git_source_code | sort 1 - _time | table commit_hash" -auth $SPLUNK_USERNAME:$SPLUNK_PASSWORD -app $APP_NAME | egrep -o '^\w+'`
    SINCE_COMMIT=$LATEST_INDEXED_COMMIT
  fi

# Get the time of the commit we are logging since.
# Note: We're getting the time, so we can specify the --since flag to git log.
#       Otherwise, we can get commits that were made earlier than we would have wanted.
  UNIX_TIME_OF_SINCE_COMMIT=`git log $SINCE_COMMIT -n 1 --pretty=format:'%ct'`


# For each commit, checkout the commit and print all the changed files matching the file pattern in $1.
  for commit in `git rev-list --all --no-color --no-renames --no-merges --reverse --since=$UNIX_TIME_OF_SINCE_COMMIT $SINCE_COMMIT..`; do
    # debug: echo "working commit: $commit" 1>&2
    git checkout $commit 1>&2 2> /dev/null
    for file in `git show $commit --pretty=format:"" --numstat |
      sed '/^$/d' |
      awk -F '\t' '{ print $3 }' |
      sed 's/ /\\ /g' |
      egrep "$file_pattern"`; do # Catch the configured file pattern. 
        echo "commit_hash=$commit repository=$GIT_REPO file=\"$file\""
        # debug: echo "commit_hash=$commit repository=$GIT_REPO file=\"$file\"" 1>&2
        cat "$file"
    done
  done
}

main
