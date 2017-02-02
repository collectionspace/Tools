## Solr4 helpers for UCB CSpace webapps

Tools (mainly shell scripts) to:
 
* deploy solr4 on Unix-like systems (Mac, Linux, perhaps even Unix).
* load the existing UCB solr datastores into the solr4 deployment.
* start and stop the solr service.

Currently there are 7 tools, some mature, but mostly unripe, raw, and needy:

* configureMultiCoreSolr.sh -- installs and configures the "standard" multicore configuration
* scp4solr.sh -- attempts to scp (copy via ssh) the available nightly solr extracts
* curl4solr.sh -- attempts to cURL the available nightly solr public extracts from the Production server
* loadAllDatasourcees.sh -- loads all the solr datasources, assuming you've downloaded the nightly .gz file(s).
* startSolr.sh -- starts Solr4 from the command line and puts it in the background. Useful only for development.
* checkstatus.sh -- *on UCB managed servers only* this script checks the ETL logs and counts records in all the solr cores
* countSolr4.sh -- if your Solr4 server is running, this script will count the records in the UCB cores

#### Suggestions for "local installs"

e.g. on your Macbook or Ubuntu labtop, for development. Sorry, no help for Windows here!

The essence:

* Install Solr4
* Configure for UCB solr datastores
* Start the Solr4 server
* Obtain the latest data extracts from UCB servers
* Unzip and load the extracts
* Verify Solr4 server works

```bash
#
# NB: if solr is *already* running, you'll need to 
#     kill it in order to start it again so it will see the new cores.

# ps aux | grep solr 
# kill <thatsolrprocess>
#
# 1. Obtain the code need (mainly bash scripts) from GitHub
#
# (you'll need to clone the repo with all the tools in it...)
# 
# let's assume that for now you'll put the solr4 data in your home directory.
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
./configureMultiCoreSolr.sh ~/Tools ~/solr4 4.10.4
#
#
# 3. Install the startup script and start solr (NB: this script puts the process into the background)
#
cd ~/solr4/ucb
cp ~/Tools/datasources/ucb/solrutils/startSolr.sh .
./startSolr.sh
#
# 4. You should now be able to see the Solr4 admin console in your browser:
#
#    http://localhost:8983/solr/
#
#    You should have a bunch of empty solr cores named things like "bampfa-public", "pahma-internal", etc.
# 
#    You can also check the contents of the solr server using the countSolr4.sh script:
#
~/Tools/datasources/ucb/solrutils/countSolr4.sh
#
# 5. download all the current nightly dumps from UCB servers. 
#
# first, make a directory to keep things neat and tidy:
cd ~
mkdir solrdumps
cd solrdumps
#
# There are two ways to get the files:
#
# to get a subset of the dumps (i.e. the public ones), you can download them via HTTP:
~/Tools/datasources/ucb/solrutils/curl4solr.sh
#
# or, if you have ssh access to either Dev or Prod, you can scp them:
~/Tools/datasources/ucb/solrutils/scp4solr.sh mylogin@cspace-prod.cspace.berkeley.edu
#
# NB: this script makes *a lot* of assumptions!
# * You must be able to connect to the CSpace production or development servers, 
#   cspace-(prod,dev).cspace.berkeley.edu
#   via secure connection, i.e. ssh.
#   to check if you can get in, try "ssh mylogin@cspace-prod.cspace.berkeley.edu". if this does not
#   work, debug that issue first before proceeding.
# * If you're off-campus, you will probably need a VPN connection. The only evidence of this
#   might be that invoking the script does nothing -- just hangs.
#   You don't need to use the script. You can simply try the following:
#       scp <your-dev-login>@cspace-prod.cspace.berkeley.edu:/tmp/4solr*.gz .
# * You may not have credentials for Prod (only dev). In this case, try:
#       scp <your-dev-login>@cspace-dev.cspace.berkeley.edu:/tmp/4solr*.gz .
#   (this will get you whatever is on Dev, which may not be the latest versions)
# * In any case, if you have to do the scp by hand, you'll also need to uncompress the files by hand:
#       gunzip -f 4solr*.gz
# * Be patient: it may take a while -- 10-20 minutes -- to download all the files. They're a bit big.
#
# 6. execute the script to load all the .csv dump files (take 15 mins or so...some biggish datasources!)
#
#    this script cleans out each solr core and then loads the dump file.
#    all the work is done via HTTP
#
~/Tools/datasources/ucb/solrutils//loadAllDatasources.sh
#
#    as noted above, you can check the contents of your Solr cores in the admin console or via
#    a script, as described in 4. above.
#
# 7. Clean up, if you wish
#
rm -rf ~/solrdump
#
# You should now have some "live data" in Solr4! Enjoy!
#
```

#### Installation on UCB Managed VMs (RHEL6)

To install solr4 on Manage VMs at UCB, from scratch, or to completely update the solr datastores,the following seems to work.
Not that this procedure is a complete ground up rebuild of the Solr4 service, and during the time
this is being executed Solr will be down.

```bash
# ssh to a server
ssh cspace-prod.cspace.berkeley.edu
# stop solr4 if it is running...assumes solr4 is already installed as a service
sudo service solr4 stop
# we install solr and its datastore here
# 
sudo su - app_solr
# if we have a clone of the Tools repo, update it:
cd ~/Tools
git pull -v
cd ~
#
# otherwise, clone it.
cd ~
git clone https://github.com/cspace-deployment/Tools
# get rid of any existing solr4 install here
sudo rm -rf ~/solr4/
# install the multicore: assume you have clones of Tools and deployandrelease repos in ~
~/Tools/datasources/ucb/solrutils/configureMultiCoreSolr.sh ~/Tools ~/solr4 4.10.4
# start solr4...assumes solr4 is already installed as a service
sudo service solr4 start
~/Tools/datasources/ucb/solrutils/checkstatus.sh
# now load the datastores (takes about 15 minutes or so, depending)
# three ways to do this:
# 1. if you're running solr on a server which has the solr ETL for UCB installed (i.e. in ~/solrdatasources)
#    you can just copy the compressed files
mkdir ~/solrdump
cd ~/solrdump
cp ~/solrdatasources/*/4solr*.gz .
gunzip *.gz
#
# 2. Otherwise, you can scp them from some other server that has them
scp cspace-prod.cspace.berkeley.edu:/home/developers/*/4solr*.gz .
# uncompress them 
gunzip 4solr*.gz
#
# 3. load them...
nohup loadAllDatasources.sh &
#
# 4. Install the ETL suite provided in ~/Tools/datasources and run it for some/all of the deployments. 
# This is a challenge if you're outside the firewall, you'll need to tunnel. Etc.
```

Caveats:

* You should read and understand these scripts before using them!
* Mostly these expect the "standard" RHEL VM environment running at IS&T/RIT
* But they will mostly run on your Mac, perhaps with some tweaking.


#### Installing solr4 as a service on UCB VMs

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
