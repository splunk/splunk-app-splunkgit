This application needs an awsome software called [Splunk](http://www.splunk.com/).

Currently the apllication is testet and the documentation written for MAC OSX 10.7

Installing Splunk
=================

Generic installation
--------------------

- [Download Splunk for your platform](http://www.splunk.com/download?r=productOverview).
- Unpack/Install Splunk by running the downloaded files.
- Follow the instruktions on screen
- When done continue to *Installing Splunkgit App* section

MAC OSX 10.7 installation
-------------------------

- Use this [direct link][] to download a gzipped tar ball of Splunk.
- Open a Terminal 
- Untar/unzip the downloaded file:
    
        `tar -xvf <FILE_NAME>`
- Start splunk:

        <SPLUNK_ROOT>/bin/splunk start
  `<SPLUNK_ROOT>` is the direcotry where you extracted splunk:

[direct link]:http://www.splunk.com/index.php/download_track?file=4.2.4/splunk/osx/splunk-4.2.4-110225-Darwin-universal.tgz&platform=MacOS&architecture=x86&version=4.2.4&typed=release&name=osx_installer&d=pro
       "Direct link to Splunk for MAC"

Installing Splunkgit App
========================

- Open Terminal app
- Goto `<SPLUNK_ROOT>`:

        cd <SPLUNK_ROOT>
- Stop splunk:

        bin/splunk stop
- Goto app directory:

        cd etc/app directory
- Downlaod the app:
        
        git clone git@github.com:splunk/splunk-app-splunkgit.git
  You can also download a released version from the [tags](./tags) page.
- Create a cirectory called local:

        mkdir local
- Copy `splunkgit.conf` from default to local:

        cp default/splunkgit.conf local
- Start splunk

        bin/splunk start

Configuration
=============

- Open Terminal app
- Goto `<SPLUNK_ROOT>`
- Stop splunk
- Edit local/splunkgit.conf with a text editor and assign the following values:

        open -e local/splunkgit.conf

    - `repo_address=` The address to the repo. Ex: `git@github.com:splunk/splunk-app-splunkgit`
    - `user_login_name=` The login name of the repo owner in github. Ex: `splunk`
    - `repo_name=` The name of the github repo. Ex: `splunk-app-splunkgit`
    - `user=` Splunk user login so our scripts can search in Splunk
    - `password=` Splunk password for the user

- Start splunk

Changing repository
===================

- Stop splunk
- Run the following command to wipe all app data from splunk:

        splunk clean eventdata -f -index splunkgit

- Change the splunkgit.conf file, as described in *Configuration* section, to point to the new repo.
- Start splunk

Third Party Libraries
=====================

- [httplib2](http://code.google.com/p/httplib2/ "httplib2")
- [joblib](http://code.google.com/p/httplib2/ "joblib")

Known Issues
============

- If you clone this repository, install the app and start up Splunk without configurating your own splunkgit.conf (as explained in *Changing repository*) splunk will get git repository data from this repositories .git directory.

License
=======

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
