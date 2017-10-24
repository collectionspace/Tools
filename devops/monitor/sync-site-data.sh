#!/bin/bash

_start=$(date +%Y%m%d-%H:%M:%S)
echo "SYNC STARTED: ${_start}" | tee -a site-sync.log

_app_user=$(whoami)
_app_name=$(echo $_app_user | sed 's/app_//')
_app_host=${_app_name}.cspace.berkeley.edu

_sync_connection=${_app_user}@${_app_host}
_sync_remote_dir='~/'${_app_name}_images/
_sync_ssh_cmd="ssh -i /home/${_app_user}/.ssh/migration"
_sync_params='-aAxXS --delete --exclude="lost+found"'
[[ "$VERBOSE" == "1" ]] && _sync_params="${_sync_params} -v"
[[ "$DRYRUN" == "1" ]] && _sync_params="${_sync_params} -n"
_sync_full="rsync -e \"$_sync_ssh_cmd\" $_sync_params ${_sync_connection}:${_sync_remote_dir} /srv/tomcat6/${_app_name}-data/${_app_name}_domain/data/"

if [[ "$DEBUG" == "1" ]]; then
  for val in \${DEBUG,VERBOSE,CSPACE_SYNC,DRYRUN} \$_app_{user,name,host} \$_sync_{connection,remote_dir,params,ssh_cmd,full}; do
    echo -n "  $val:" | tee -a site-sync.log
    eval echo $val | tee -a site-sync.log
  done
fi

if [[ "$CSPACE_SYNC" == "1" ]]; then
  # do the sync
   rsync -e "$_sync_ssh_cmd" $_sync_params ${_sync_connection}:${_sync_remote_dir} /srv/tomcat6/${_app_name}-data/${_app_name}_domain/data/ 2>&1 | tee -a site-sync.log
fi

_end=$(date +%Y%m%d-%H:%M:%S)
echo "SYNC ENDED: ${_end}" | tee -a site-sync.log
