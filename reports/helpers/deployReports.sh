TENANT=$1
cd ~
rm -rf Tools
git clone https://github.com/cspace-deployment/Tools.git
cp Tools/reports/${TENANT}/*.jrxml tomcat6-${TENANT}/cspace/reports
rm tomcat6-${TENANT}/cspace/reports/*.jasper
rm -rf Tools
echo "***** reports redeployed! *******"
