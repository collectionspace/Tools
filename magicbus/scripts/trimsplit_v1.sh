#!/bin/bash


# --------------------------------------------------
# Trim the resulting (final) XML file (use TrimObj3)
# --------------------------------------------------
java -Xms256M -Xmx1024M -classpath ../../bin trimXml.TrimObj3 mrg30_objectStatus.2012-06-185.xml mrg30_objectStatus.2012-06-185.xml_trim.xml > objtrim_msg_2012-06-185.msg

# -------------------------------------------------------
# Split the resulting (final) XML file before import 
# --- last argument is "prefix" of resulting split-files
# -------------------------------------------------------
java -Xms256M -Xmx1024M -classpath ../../bin splitXml.SplitImport 3500 mrg30_objectStatus.2012-06-185.xml_trim.xml mrg30.2012-06-185_trim > objmrg30.2012-06-185_split.msg
