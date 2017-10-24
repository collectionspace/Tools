#
# this script will deploy all reports in GitHub for a tenant.
#
# if must be run on the CSpace server in question
#
# NB: this only works for the UCB tenant, using the Tools repo.
#     it could, of course be customized to be more general
#
if [ $# -ne 1 ]; then
    echo "Usage: deployReports.sh tenant"
    exit
fi
TENANT=$1
cd ~
rm -rf Tools
git clone https://github.com/cspace-deployment/Tools.git
cp Tools/reports/${TENANT}/*.jrxml tomcat6-${TENANT}/cspace/reports
rm tomcat6-${TENANT}/cspace/reports/*.jasper
rm -rf Tools
echo "***** reports redeployed! *******"
