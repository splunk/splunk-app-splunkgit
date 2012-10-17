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

# Script pulls the repositories configured in local/splunkgit.conf
# Author: Petter Eriksson

SCRIPT_HOME=$(dirname $0)
source $SCRIPT_HOME/shell_variables.sh 

#Initializing
GIT_REPO=
GIT_REPO_FOLDER=
GIT_REPOS_HOME=
chosen_repository=

main ()
{
for repository in `$SPLUNK cmd python $SCRIPT_HOME/splunkgit_settings.py`
do
  GIT_REPO=$repository
  GIT_REPO_FOLDER=`echo $GIT_REPO | sed 's/.*\///'`
  GIT_REPOS_HOME=$APP_HOME/git-repositories
  chosen_repository=$GIT_REPOS_HOME/$GIT_REPO_FOLDER

  if [ "$GIT_REPO" = "" ]; then
    echo "Could not find configured git repository. Have you configured splunkgit.conf? Read README.md for more information." 1>&2
  else
    if [ ! -d "$chosen_repository" ]; then
      echo "repository does not exist!" 1>&2
      fetch_git_repository
    fi
  fi
done
}

fetch_git_repository ()
{
  echo "fetching git repo data for repository: $repository" 1>&2
  error_output=err.out
  mkdir -p $GIT_REPOS_HOME
  git clone --mirror $GIT_REPO $chosen_repository 1>&2
  git_exit_code=$?
  if [[ $git_exit_code != 0 ]]; then
    echo "Unable to clone repository: $GIT_REPO" 1>&2
  fi
}

main
