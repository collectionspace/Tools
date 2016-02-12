Solr4 helpers for CSpace webapps
================================

Tools (mainly shell scripts) to:
 
* deploy solr4 on Unix-like systems (Mac, Linux, perhaps even Unix).
* load the existing UCB solr datastores into the solr4 deployment.
* start and stop the solr service.

Currently there are 10 tools, some mature, but mostly unripe, raw, and needy:

* configureMultiCoreSolr.sh -- installs and configures the "standard" multicore configuration
* scp4solr.sh -- attempts to scp (copy via ssh) the available nightly solr extracts
* installsolrpy.sh -- tries to install the solrpy module so Python can talk to Solr. ONLY NEEDED FOR UCB REDHAT!
* loadAllDatasourcees.sh -- loads all the solr datasources, assuming you've downloaded the nightly .gz file(s).
* startSolr.sh -- starts Solr4 from the command line and puts it in the background. Useful only for development.

Suggestions for "local installs", e.g. on your Macbook or Ubuntu labtop, for development.

The essence:

* Install Solr4; configure for UCB solr datastores
* Start the Solr4 service
* Attempt to obtain the latest data from UCB servers (you must have ssh access!)
* Unzip and load the latest data.

```bash
# 1. Obtain the code need (mainly bash scripts) from GitHub
#
# (you'll need to clone the repo with all the tools in it...)
#
# 
cd ~
git clone https://github.com/cspace-deployment/Tools
# 
# 2. configure the Solr multicore deployment using configureMultiCoreSolr.sh
#
# NB: takes 3 arguments! Assumes you have cloned the Tools repo...use the full path please
#
# run the following script which unpacks solr, makes the UCB cores in multicore, copies the customized files needed
#
cd ~/Tools/datasources/ucb/solrutils
./configureMultiCoreSolr.sh /User/myhomedir/Tools solr4 4.10.4
#
# NB: if solr is *already* running and you did not kill it before reconfiguring the cores, you'll need to 
#     kill it in order to start it again so it will see the new cores.
# ps aux | grep solr 
# kill <thatsolrprocess>
#
# 3. Install the startup script and start solr (NB: this script puts the process into the background)
#
cd ~/solr4/ucb
cp ~/Tools/datasources/ucb/solrutils/startSolr.sh .
./startSolr.sh
#
# 4. You should now be able to see the Solr4 admin console in your browser.
#    You should have a bunch of empty solr cores named things like "bampfa-public", "pahma-internal", etc.
# 
# 5. download all the current nightly dumps from UCB servers.
#    NB: ssh credentials required!
#
# for tidiness, we suggest make a directory to hold the various dumps. You'll be updating them from time to time.
#
mkdir ~/4solr
cd ~/4solr
~/Tools/datasources/ucb/solrutils/scp4solr.sh
# 
#
# 6. execute the script to load all the .csv dump files (take 15 mins or so...some biggish datasources!)
#
#
~/Tools/datasources/ucb/solrutils//loadAllDatasources.sh
#
```


To install solr4 on Manage VMs at UCB, from scratch, or to completely update the solr datastores,the following seems to work:

```bash
# ssh to a server
ssh cspace-prod.cspace.berkeley.edu
# stop solr4 if it is running...assumes solr4 is already installed as a service
sudo service solr4 stop
# we install solr and its datastore here
# 
sudo su - app_solr
# get rid of any existing solr4 install here
sudo rm -rf solr4/
# install the multicore: assume you have clones of Tools and deployandrelease repos in ~
~/deployandrelease/configureMultiCoreSolr.sh ~/Tools solr4 4.10.4
# start solr4...assumes solr4 is already installed as a service
sudo service solr4 start
# now load the datastores (takes about 15 minutes or so, depending)
cd ~/deployandrelease/
# three ways to do this:
# 1. if you're running solr on a server which has the solrr ETL for UCB installed (i.e. in /home/developers)
#    you can just copy the compressed files
cp /home/developers/*/4solr*.gz .
gunzip *.gz
# 2. Otherwise, you can scp them from some other server that has them
scp dev.cspace.berkeley.edu:/home/developers/*/4solr*.gz .
# uncompress them and load them
gunzip 4solr*.gz
nohup loadAllDatasourcees.sh &
# 3. Install the ETL suite in Tools/datasource and run it for some/all of the deployments. 
# This is very hard, as if you're outside the firewall, you'll need to tunnel. Etc.
```

Caveats:

* You should read and understand these scripts before using them!
* Mostly these expect the "standard" RHEL VM environment running at IS&T/RIT
* But they will mostly run on your Mac, perhaps with some tweaking.


Install solr4 as a service on UCB VMs

```bash
# install the solr4.service script in /etc/init.d
sudo cp solr4.service /etc/init.d/solr4
# check that the script works
sudo service solr4 status
# if solr is installed as described above, the following should work
sudo service solr4 start
# you can also check if the service is running this way:
ps aux | grep java
# the logs are in the following directory:
ls -ltr /usr/local/share/solr4/ucb/logs/
# e.g.
less  /usr/local/share/solr4/ucb/logs/solr.log 
less  /usr/local/share/solr4/ucb/logs/2015_03_21-085800651.start.log 
```
