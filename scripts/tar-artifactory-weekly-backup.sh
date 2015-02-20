#!/bin/bash

# Simple script to remove all but the most recent week's
# backup of the CollectionSpace project Maven repository
# (using Artifactory on nightly.collectionspace.org)
# and then 'tar' up that most recent backup.

# ####################
# Options
# ####################

#
# Uncomment during debugging, to print verbose output:
#
# set -x

# ####################
# Constants
# ####################

#
# Artifactory weekly backups will be created as timestamp-named
# subdirectories within the following directory:
#
ARTIFACTORY_WEEKLY_BACKUP_DIR=/var/lib/artifactory/backup/backup-weekly
MAX_DIRS=2

# ####################
# Main script
# ####################

#
# Get a list of all the weekly backup directories.
#
COUNT=0
for file in $ARTIFACTORY_WEEKLY_BACKUP_DIR/*
do
    if [[ -d $file ]]; then
        # For each directory encountered, check that it 1) has a name
        # matching Artifactory's weekly backup pattern (e.g. "20150218.030000"),
        # and 2) is non-empty.
        if [[ "$file" =~ .*?/[0-9]{8}\.[0-9]{6}$ ]] && [ "$(ls -A $file)" ]; then
            let COUNT=COUNT+1
            # If a directory fulfills both of those criteria, add it to an array
            # of directory paths
            dirlist[$COUNT]=$file
        fi
    fi
done

#
# Get the count of Artifactory weekly backup directories found.
#
let DIRCOUNT=${#dirlist[@]}
echo "$DIRCOUNT backup directories were found ..."

# If there are no weekly backup directories found, then quit.
if [ "$DIRCOUNT" -le 0 ]; then
  echo "No backup directories were found ..."
  exit 0
fi

#
# If there is more than one weekly backup directory found,
# then we don't know how to handle this, so quit.
#
# TODO: We might instead want to sort the backup directories by
# name (which reflect ISO 8601-style timestamps) and delete all
# but the most recent non-empty backup directory.
#
# And if sufficient free disk space is present, we might
# even retain more than one previous weekly backup.
#
if [ "$DIRCOUNT" -ge "$MAX_DIRS" ]; then
  echo "More than $MAX_DIRS backup directories were found."
  echo "Not sure how to proceed: no action was taken."
  exit 1
fi

#
# Otherwise ...
#
# Delete any existing tarred and/or tarred and gzipped backups
# in this directory.
#
unamestr=`uname`
if [[ "$unamestr" == "Linux" ]]; then
    find $ARTIFACTORY_WEEKLY_BACKUP_DIR -regextype posix-egrep -regex ".*/[0-9]{8}\.[0-9]{6}\.tar" -delete
    find $ARTIFACTORY_WEEKLY_BACKUP_DIR -regextype posix-egrep -regex ".*/[0-9]{8}\.[0-9]{6}\.tar\.gz" -delete
elif [[ "$unamestr" == "Darwin" ]]; then
    find -E $ARTIFACTORY_WEEKLY_BACKUP_DIR -regex ".*/[0-9]{8}\.[0-9]{6}\.tar" -delete
    find -E $ARTIFACTORY_WEEKLY_BACKUP_DIR -regex ".*/[0-9]{8}\.[0-9]{6}\.tar\.gz" -delete
fi

#
# Tar the most recent week's backup directory
#
CURRENT_WEEKLY_BACKUP_DIR=${dirlist[1]}
tar -cf $CURRENT_WEEKLY_BACKUP_DIR.tar $CURRENT_WEEKLY_BACKUP_DIR
