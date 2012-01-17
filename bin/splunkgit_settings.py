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

import splunk.clilib.cli_common
import re

'''
Functions for retriveing settigs from splunkgit conf file.
Author: Emre Berge Ergenekon, Petter Eriksson
'''
SPLUNKGIT_GIT_SETTINGS = splunk.clilib.cli_common.getConfStanza('splunkgit','git')
SPLUNK_SETTINGS = splunk.clilib.cli_common.getConfStanza('splunkgit','splunk')

class GithubRepository(object):

    def __init__(self, repo_address, user, repo):
        self._repo_address = repo_address
        self._user = user
        self._repo = repo

    def get_repo_address(self):
        return self._repo_address

    def get_user(self):
        return self._user

    def get_repo(self):
        return self._repo

    @classmethod
    def new_from_repo_address(cls, repo_address):
        user = GithubRepository.get_user_from_repo_address(repo_address)
        repo = GithubRepository.get_repo_from_repo_address(repo_address, user)
        if user is None or repo is None:
            return None
        return GithubRepository(repo_address, user, repo)

    @classmethod
    def get_user_from_repo_address(cls, repo_address):
        user_match = re.search('(?<=github\.com.)(.*)(?=/)', repo_address) # match anything after github.com until /
        if user_match is not None:
                return user_match.group(0)
        else:
            return None

    @classmethod
    def get_repo_from_repo_address(cls, repo_address, user):
        repo_match = re.search("(?<=%s/)(.*)(?=\.git)" % user, repo_address) # match <something>.git after user/
        if repo_match is not None:
            return repo_match.group(0)
        else:
            return None

def git_repo_addresses():
    return SPLUNKGIT_GIT_SETTINGS['repo_addresses']

def splunk_user_name():
    return SPLUNK_SETTINGS['user']

def splunk_password():
    return SPLUNK_SETTINGS['password']

def github_repositories():
    space_separated_repo_addresses = git_repo_addresses()
    repo_addresses = space_separated_repo_addresses.split(' ')
    return github_repos_from_repo_addresses(repo_addresses)

def github_repos_from_repo_addresses(repo_addresses):
    github_repos = []
    for repo_address in repo_addresses:
        github_repo = GithubRepository.new_from_repo_address(repo_address)
        if github_repo is not None:
            github_repos.append(github_repo)
    return github_repos

if __name__ == '__main__':
    print git_repo_addresses()
