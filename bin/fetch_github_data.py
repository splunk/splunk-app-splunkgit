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

'''
This script polls usefull github data from github
Author: Emre Berge Ergenekon, Petter Eriksson
'''

#Import from std lib
from time import localtime, strftime


#import own classes
from SplunkAPI import SplunkAPI
from GithubAPI import GithubAPI
import splunkgit_settings

def fetch_single_github_repo_data(github_user, github_repo):
    github_api = GithubAPI(github_user, github_repo)
    time_stamp = strftime("%Y-%m-%d %H:%M:%S %z", localtime())    

    repo = github_api.repo()
    if repo is not None:
        print '[{0}] github_watcher_count={1}'.format(time_stamp, repo['watchers'])
        print '[{0}] github_forks_count={1}'.format(time_stamp, repo['forks'])

    splunk_api = SplunkAPI(splunkgit_settings.splunk_user_name(), splunkgit_settings.splunk_password())
    since = splunk_api.time_of_last_updated_issue()
    if since is None:
        since = '1900-01-01T00:00:01Z'
    all_issues =  github_api.issues_since(since)
    for issue in all_issues :
        print u'[{0}] github_issue_number={1} github_issue_state="{2}" github_issue_comment_count={3} github_issue_reporter="{4}" github_issue_title="{5}" github_issue_close_time="{6}" github_issue_update_time="{7}" github_issue_creation_time="{8}"'.format(time_stamp, issue['number'], issue['state'], issue['comments'], issue['user']['login'], issue['title'], issue['closed_at'], issue['updated_at'], issue['created_at'])

if __name__ == '__main__':
    for github_user_repo in splunkgit_settings.github_user_repos():
        github_user = github_user_repo.get_user()
        github_repo = github_user_repo.get_repo()
        fetch_single_github_repo_data(github_user, github_repo)
