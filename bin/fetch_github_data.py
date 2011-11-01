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
import os
import sys

#import from 3rd party lib
LIB_PATH = os.path.abspath(os.path.join(__file__, '..', '..', 'lib'))
sys.path.insert(0, LIB_PATH)
from joblib import Parallel, delayed

#import own classes
from SplunkAPI import SplunkAPI
from GithubAPI import GithubAPI
from splunkgit_settings import github_repo_name, github_user_login_name

GITHUB_USER = github_user_login_name()
GITHUB_REPO = github_repo_name()

def get_total_fork_count(forks, run_as_single_job=False):
    total_number_of_forks = 1
    total_number_of_forks += _count_forks_in_all_depths(forks, run_as_single_job)
    return total_number_of_forks

def _count_forks_in_all_depths(forks, run_as_single_job=False):
    if run_as_single_job:
        return _count_forks_in_all_depths_on_single_thread(forks)
    else:
        return _count_forks_in_all_depths_on_multiple_threads(forks)

def _count_forks_in_all_depths_on_single_thread(forks):
    total_number_of_forks = 0
    for fork in forks:
        total_number_of_forks += _get_total_fork_count_inner_loop(fork)
    return total_number_of_forks

def _count_forks_in_all_depths_on_multiple_threads(forks):
    fork_counts = Parallel(n_jobs=16)(delayed(_get_total_fork_count_inner_loop)(forks[i]) for i in range(len(forks)))
    return sum(fork_counts)

def _get_total_fork_count_inner_loop(fork):
    if fork['private'] == True:
        return 0
    else:
        return _get_total_fork_count_for_public_fork(fork)

def _get_total_fork_count_for_public_fork(fork):
    github_user = fork['owner']['login']
    github_fork = fork['name']
    github_api = _get_github_api_for(github_user, github_fork)
    return get_total_fork_count(github_api.forks(), True)

def _get_github_api_for(github_user, github_repo):
    return GithubAPI(github_user, github_repo)
    
if __name__ == '__main__':
    github_api = _get_github_api_for(GITHUB_USER, GITHUB_REPO)
    time_stamp = strftime("%Y-%m-%d %H:%M:%S %z", localtime())    

    print '[{0}] github_watcher_count={1}'.format(time_stamp, len(github_api.watchers()))
    
    splunk_api = SplunkAPI('admin','changeme')
    since = splunk_api.time_of_last_updated_issue()
    if since is None:
        since = '1900-01-01T00:00:01Z'
    all_issues =  github_api.issues_since(since)

    for issue in all_issues :
        print u'[{0}] github_issue_number={1} github_issue_state="{2}" github_issue_comment_count={3} github_issue_reporter="{4}" github_issue_title="{5}" github_issue_close_time="{6}" github_issue_update_time="{7}" github_issue_creation_time="{8}"'.format(time_stamp, issue['number'], issue['state'], issue['comments'], issue['user']['login'], issue['title'], issue['closed_at'], issue['updated_at'], issue['created_at'])
    print '[{0}] github_forks_count={1}'.format(time_stamp, get_total_fork_count(github_api.forks()))
