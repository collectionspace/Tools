#!/bin/bash
set verbose

find temp/location -type f -mtime +365 -delete
find temp/relation -type f -mtime +365 -delete
find temp/location/done -type f -mtime +365 -delete
find temp/location/done_id -type f -mtime +365 -delete
find temp/relation/done -type f -mtime +365 -delete
