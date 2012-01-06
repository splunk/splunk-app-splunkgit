Splunk > Splunkgit
==================

This application needs an awesome software called [Splunk](http://www.splunk.com/).

Currently the application is tested and the documentation written for Mac OS X 10.7

Stuff in this repository are mentioned on a four part blog series.

- [part 1](http://blogs.splunk.com/2011/11/9/splunkgit-part-1)
- [part 2](http://blogs.splunk.com/2011/11/9/splunkgit-part-2)
- [part 3](http://blogs.splunk.com/2011/11/17/splunkgit-part-3)
- [part 4](http://blogs.splunk.com/2011/11/18/splunkgit-part-4)

Getting started
---------------

### Installing splunk

#### Generic instructions

- [Download Splunk for your platform](http://www.splunk.com/download?r=productOverview).
- Unpack/Install Splunk by running the downloaded files.
- Follow the instructions on screen
- When done continue to *Installing Splunkgit App* section

`<SPLUNK_ROOT>` is the direcotry where you extracted splunk:

[direct link]:http://www.splunk.com/index.php/download_track?file=4.2.4/splunk/osx/splunk-4.2.4-110225-Darwin-universal.tgz&platform=MacOS&architecture=x86&version=4.2.4&typed=release&name=osx_installer&d=pro
       "Direct link to Splunk for MAC"

### Installing splunkgit

- Make sure splunk is not running
- Open Terminal app
- Goto `<SPLUNK_ROOT>`: `cd <SPLUNK_ROOT>`
- Goto app directory: `cd etc/apps`
- Download the app: `git clone git://github.com/splunk/splunk-app-splunkgit.git`  
  You can also download a released version from the [tags](./splunk-app-splunkgit/tags) page.

### Configuration

- Make sure splunk is not running
- Open Terminal app
- Goto `<SPLUNK_ROOT>/etc/apps/splunk-app-aplunkgit`
- Edit local/splunkgit.conf with a text editor (`open -e local/splunkgit.conf`) and assign the following values:
    - `repo_addresses=` The addresses to the repos, use the read-only address. Ex: `git://github.com/splunk/splunk-app-splunkgit.git`. You can have one or multiple repositories, space separated
    - `user_login_name=` The login name of the repo owner in github. Ex: `splunk`
    - `repo_name=` The name of the github repo. Ex: `splunk-app-splunkgit`
    - `user=` Splunk user login so our scripts can search in Splunk
    - `password=` Splunk password for the user

### Changing repository

- Make sure splunk is not running
- Run the following command to wipe all app data from splunk:

        splunk clean eventdata -f -index splunkgit

- Change the splunkgit.conf file, as described in *Configuration* section, to point to the new repo.

### Starting and stopping Splunk

- Open Terminal
- Goto `<SPLUNK_ROOT>`: `cd <SPLUNK_ROOT>`
- Start splunk `bin/splunk start`
    - On you web browser goto `http://localhost:8000`
    - If asked enter your name and user name (default value is **admin:password**)
    - If you change the password, you also need the change the configuration file to match this.
- Stop splunk: `bin/splunk stop`

Third party libraries
---------------------

- [httplib2](http://code.google.com/p/httplib2/ "httplib2")
- [joblib](http://code.google.com/p/httplib2/ "joblib")

Known issues
------------

- If you clone this repository, install the app and start up Splunk without configurating your own splunkgit.conf (as explained in *Changing repository*) splunk will get git repository data from this repositories .git directory.
- Currently only read-only addresses work. Don't use `https` or `git@github` addresses. 

License
-------

    Copyright 2011 Splunk, Inc.
    
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    
    http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
