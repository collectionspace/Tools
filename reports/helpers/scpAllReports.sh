#
# copies all report .jrxml file from prod servers to this git clone/fork
#
# good for checking the prod servers for unchecked reports and diffs...
#
cd ..
scp pahma.cspace.berkeley.edu:/usr/local/share/tomcat/cspace/reports/*.jrxml pahma/
scp bampfa.cspace.berkeley.edu:/usr/local/share/tomcat/cspace/reports/*.jrxml bampfa/
scp botgarden.cspace.berkeley.edu:/usr/local/share/tomcat/cspace/reports/*.jrxml botgarden
scp cinefiles.cspace.berkeley.edu:/usr/local/share/tomcat/cspace/reports/*.jrxml cinefiles/
scp ucjeps.cspace.berkeley.edu:/usr/local/share/tomcat/cspace/reports/*.jrxml ucjeps/
rm */acq_basic.jrxml  
