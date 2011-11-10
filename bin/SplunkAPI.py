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
Created on Oct 31, 2011

@author: Petter Eriksson
'''

import splunk.auth
import splunk.search as search
from GithubAPI import GithubAPI
import time

from splunkgit_settings import github_repo_name, github_user_login_name

GITHUB_USER = github_user_login_name()
GITHUB_REPO = github_repo_name()

class SplunkAPI(object):

    def __init__(self, username, password):
        splunk.auth.getSessionKey(username, password)
    
    def time_of_last_updated_issue(self):
        last_updated_issue_search = self._search_for_last_updated_issue()
        return self._get_update_time_from_search(last_updated_issue_search)
        
    def _search_for_last_updated_issue(self):
        issue_search = search.dispatch('search index=splunkgit sourcetype="github_data" github_issue_update_time=* | sort -str(github_issue_update_time) | head 1')
        while not issue_search.isDone:
            time.sleep(0.5) #for a while
        return issue_search
    
    def _get_update_time_from_search(self, search):
        if len(search) is 0:
            return None
        else: 
            return self._get_update_time_from_head_of_search(search)
    
    def _get_update_time_from_head_of_search(self, search):
        return search.events[0]['github_issue_update_time']
