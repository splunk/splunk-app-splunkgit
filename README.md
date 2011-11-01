Installation
============

- Stop splunk
- Put the splunkgit directory into <SPLUNK_HOME>/etc/app directory
- Start splunk

Configuration
=============

- Stop splunk
- Copy the file <splunkgit root>/default/splunkgit.conf to  <splunkgit root>/local
- Edit the splunkgit.conf and assign values to:
    - 'repo_address=' The address to the repo. Ex: git@github.com:splunk/splunk-app-splunkgit
    - 'user_login_name=' The login name of the repo owner in github. Ex: splunk
    - 'repo_name=' The name of the github repo. Ex: splunk-app-splunkgit
- Start splunk

Changing repository
===================

- Stop splunk
- Run the following command to wipe all app data from splunk:

        splunk clean eventdata -f -index splunkgit
- Change the splunkgit.conf file, as described in [Configuration] section, to point to the new repo.
- Start splunk

Third Party Libraries
=====================

- [httplib2](http://code.google.com/p/httplib2/)
- [joblib](http://code.google.com/p/httplib2/)