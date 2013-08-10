# setenv.sh sourced from catalina.sh

[ -n "$CATALINA_HOME" ] || CATALINA_HOME=

export JAVA_HOME=
export LANG=en_US.UTF-8

if [ -d $CATALINA_HOME/cspace ]
then
  export CATALINA_HOME
  export CATALINA_PID=$CATALINA_HOME/bin/tomcat.pid
  export CSPACE_JEESERVER_HOME=$CATALINA_HOME
  export JPDA_ADDRESS=8080
  export JPDA_TRANSPORT=dt_socket
  export CATALINA_OPTS=' -Xmx1024m -Xms256m -XX:MaxPermSize=384m'
  export DB_PASSWORD=
  export DB_PASSWORD_CSPACE=
  export DB_PASSWORD_NUXEO=
  export PATH=$JAVA_HOME/bin:/bin:/usr/bin:$CATALINA_HOME/bin
  LOG=$CATALINA_HOME/logs/catalina.out
  TCPID=""
else
  export CATALINA_HOME=""
fi

