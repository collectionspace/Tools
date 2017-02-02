#!/bin/bash

# Simple script to remove all but the most recent week's
# backup of the CollectionSpace project Maven repository
# (using Artifactory on nightly.collectionspace.org)
# and then 'tar' up that most recent backup.
# See http://issues.collectionspace.org/browse/CSPACE-6443


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

# ####################
# Main script
# ####################

#
# Get a list of all the weekly backup directories.
#
COUNT=0
TMP_DIR_REGEX='.*/[0-9]{8}\.[0-9]{6}\.tmp$'
BACKUP_DIR_REGEX='.*/[0-9]{8}\.[0-9]{6}'

for file in $ARTIFACTORY_WEEKLY_BACKUP_DIR/*
do
    if [[ -d $file ]]; then
        #
        # If any temporary directory whose name matches Artifactory's
        # weekly backup temporary directory name pattern
        # (e.g. "20150218.030000.tmp") is found, then quit.
        #
        # This likely indicates that some backup was incomplete,
        # and it isn't safe to proceed further without human review.
        #
        if [[ "$file" =~ $TMP_DIR_REGEX ]]; then
            echo "Temporary directory (from a possibly incomplete Artifactory backup)"
            echo "was found."
            echo "Not sure how to proceed: no action was taken."
            exit 1
        fi
        #
        # For every other directory encountered, check that it:
        # 1) has a name matching Artifactory's weekly backup name pattern
        # (e.g. "20150218.030000"); and
        # 2) is non-empty.
        #
        # If it does, add it to the list of backup directories found.
        #
        if [[ "$file" =~ $BACKUP_DIR_REGEX ]] && [ "$(ls -A $file)" ]; then
            let COUNT=COUNT+1
            #
            # If a directory fulfills both of those criteria, add it to an array
            # of directory paths
            #
            dirlist[$COUNT]=$file
        fi
    fi
done

#
# Get the count of Artifactory weekly backup directories found.
#
let DIRCOUNT=${#dirlist[@]}
#
# Uncomment for debugging:
#
# echo "$DIRCOUNT backup directories were found ..."

#
# If there are no weekly backup directories found, then quit.
#
if [ "$DIRCOUNT" -eq 0 ]; then
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
MAX_DIRS=2
if [ "$DIRCOUNT" -ge "$MAX_DIRS" ]; then
  echo "More than $MAX_DIRS backup directories were found."
  echo "Not sure how to proceed: no action was taken."
  exit 1
fi

#
# Otherwise ...
#
# (Note that the relevant entry in the dirlist array will be
# at index position 1, not 0, per the 'do' loop above.)
#
CURRENT_WEEKLY_BACKUP_DIR=${dirlist[1]}
echo "Current weekly backup directory found at $CURRENT_WEEKLY_BACKUP_DIR ..."

#
# Delete any existing tarred and/or tarred and gzipped backups
# in this directory.
#
unamestr=`uname`
if [[ "$unamestr" == "Linux" ]]; then
    echo "Looking for older tarred backups to delete, to free up disk space ..."
    find $ARTIFACTORY_WEEKLY_BACKUP_DIR -regextype posix-egrep -regex ".*/[0-9]{8}\.[0-9]{6}\.tar" -delete -print
    find $ARTIFACTORY_WEEKLY_BACKUP_DIR -regextype posix-egrep -regex ".*/[0-9]{8}\.[0-9]{6}\.tar\.gz" -delete -print
elif [[ "$unamestr" == "Darwin" ]]; then
    echo "Looking for older tarred backups to delete, to free up disk space ..."
    find -E $ARTIFACTORY_WEEKLY_BACKUP_DIR -regex ".*/[0-9]{8}\.[0-9]{6}\.tar" -delete -print
    find -E $ARTIFACTORY_WEEKLY_BACKUP_DIR -regex ".*/[0-9]{8}\.[0-9]{6}\.tar\.gz" -delete -print
fi

#
# Tar up the current week's backup directory
#
echo "Tarring up the current week's backup directory ..."
tar -cf $CURRENT_WEEKLY_BACKUP_DIR.tar $CURRENT_WEEKLY_BACKUP_DIR
