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

import json
import httplib2
import re

import inspect

class GithubAPI(object):
    '''
    Author: Emre Berge Ergenekon
    Contains functions for making some of the Github v3 API requests.
    '''     
    _base_url = ''
    
    def __init__(self, user_name, repo_name):
        self._base_url = 'https://api.github.com/repos/{0}/{1}'.format(user_name, repo_name)
    
    def watchers(self):
        return self.make_request('watchers')
    
    def open_issues(self):
        return self._issues('open')
    
    def closed_issues(self):
        return self._issues('closed')
    
    def _issues(self, state='open'):
        return self.make_request('issues?state={0}'.format(state))

    def issues_since(self, since):
        request_issues_since = 'issues?since={0}'.format(since)
        return self._open_issues(request_issues_since) + self._closed_issues(request_issues_since)

    def _open_issues(self, request_prefix):
        return self.make_request(request_prefix + '&state=open')

    def _closed_issues(self, request_prefix):
        return self.make_request(request_prefix + '&state=closed')
    
    def forks(self):
        return self.make_request('forks')
    
    def repo(self):
        request = self.make_request('')
        if request:
            return request[0]
        else:
            return None

    def make_request(self, partial_url):
        http = self._get_http()
        next_url = self._create_full_api_url(partial_url)
        last_url = ''
        all_responses = []
        while True :
            response, content = http.request(next_url)
            if response.status != 200: break
            response_as_json = json.loads(content)
            if type(response_as_json) is dict: response_as_json = [response_as_json]
            all_responses[len(all_responses):] = response_as_json
            if next_url == last_url or not self._has_link_header(response): break
            next_url = self._link_header_value_for_reletion(response, 'next')
            last_url = self._link_header_value_for_reletion(response, 'last')
        return all_responses
    
    def _get_http(self):
        #disable ssl_certificate_validation because of an issue with python 2.7.2 and httplib2 0.7.x
        #link: http://code.google.com/p/httplib2/issues/detail?id=154
        if 'disable_ssl_certificate_validation' in inspect.getargspec(httplib2.Http.__init__)[0]:
            return httplib2.Http(disable_ssl_certificate_validation=True)
        else:
            return httplib2.Http()
        
    def _create_full_api_url(self, partial_url):
        if partial_url == '':
            return '{base_url}?per_page=100'.format(base_url=self._base_url)
        else:
            return '{base_url}/{partial_url}{parameter_separator}per_page=100'.format(base_url=self._base_url, partial_url=partial_url, parameter_separator=('&' if '?' in partial_url else '?'))
    
    def _link_header_value_for_reletion(self, response, rel):
        linkHeader = response['link']
        pattern = '(?<=\<)[^>]+?(?=\>; rel="{0}")'.format(rel)
        value = re.search(pattern, linkHeader).group(0)
        return value
    
    def _has_link_header(self, response):
        return 'link' in response
    
''' The code here should be rewritten to build and return a list of the forks instead of just counting them '''
'''
import os
import sys

#import from 3rd party lib
LIB_PATH = os.path.abspath(os.path.join(__file__, '..', '..', 'lib'))
sys.path.insert(0, LIB_PATH)
from joblib import Parallel, delayed


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
'''