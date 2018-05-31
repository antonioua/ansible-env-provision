#!/bin/bash


STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

#FUNCTION_TO_EXECUTE=$1
ARG2=$2
ARG3=$3



# TELNET checks
function telnet_check() {
#       telnet $ARG2 443
#       if [ $? -eq 0 ]; then
#               CHECK="OK"
#       else
#               CHECK="FAILED"
#       fi
echo -e ${ARG2} $ARG3 && exit
}


# SHMOXI checks
function SHMOXI_check() {

HOST_NAME=${ARG2}
PORT=${ARG3}
INSECURE=""


if [[ ${PORT} == "443" ]]; then
    PROTO="https"
else
    PROTO="http"
fi

if [[ ${HOST_NAME} == "ext-test-smokeoffice.project.com" ]]; then
    ENDPOINT="${PROTO}://${HOST_NAME}/SHMOXIxmlserver"
elif [[ ${HOST_NAME} == "ext-test04-smokeoffice.project.com" ]]; then
    ENDPOINT="${PROTO}://${HOST_NAME}/SHMOXIxmlserver_product"
    INSECURE="--insecure"
elif [[ ${HOST_NAME} == "test05-smokeoffice.project.com" ]]; then
    ENDPOINT="${PROTO}://${HOST_NAME}/SHMOXIxmlserver_product-gib"
    INSECURE="--insecure"
elif [[ ${HOST_NAME} == "test-overseer.project.gi" ]]; then
    ENDPOINT="${PROTO}://${HOST_NAME}/SHMOXIxmlserver-gib"
    INSECURE="--insecure"
else
    ENDPOINT="${PROTO}://${HOST_NAME}/SHMOXIxmlserver_product"
fi

GET_SERVER_STATUS=`curl -s -o /dev/null -I -w "%{http_code}\\n" ${ENDPOINT} -o /dev/null ${INSECURE}`

if [[ ${GET_SERVER_STATUS} -eq 200 ]]; then
    CHECK="OK"
    RETURN_PHRASE="${HOST_NAME} returns code: ${GET_SERVER_STATUS}"
elif [[ ${GET_SERVER_STATUS} -eq 503 ]]; then
    CHECK="FAILED"
    RETURN_PHRASE="${HOST_NAME} returns code: ${GET_SERVER_STATUS} Service Temporarily Unavailable"
else
    CHECK="FAILED"
    RETURN_PHRASE="SHMOXI not working, ${HOST_NAME} returns code: ${GET_SERVER_STATUS}"
fi
}


function new_relic_live_players() {
APPID=${ARG2}
APIKEY=${ARG3}
PROTO="https"

live_ssessions=`curl -s -H "Accept: application/json" -H "X-Query-Key: ${APIKEY}" \
            "${PROTO}://insights-api.newrelic.com/v1/accounts/${APPID}/query?nrql=SELECT%20uniqueCount(session)%20FROM%20PageView%20WHERE%20appName='LB.COM'%20SINCE%201%20minutes%20ago" \
            | sed -e 's/.*"uniqueCount"://g' -e 's/}.*$//g'`
if [ $? -ne 0 ]
  then
    CHECK="FAILED"
    #return 1
  else
    CHECK="OK"
    RETURN_PHRASE="Live Sessions: ${live_ssessions}" 
    #return 0
fi
}

# NR checks
function new_relic_error_rate() {

APPID=${ARG2}
APIKEY=${ARG3}
PROTO="https"

# To obtain the error count:
error_count=`curl -s -X GET "${PROTO}://api.newrelic.com/v2/applications/${APPID}/metrics/data.xml" -H "X-Api-Key:${APIKEY}" \
    -i -d 'names[]=Errors/all&values[]=error_count&summarize=true' | grep "<error_count>" |\
    sed -e 's/<error_count>//g' -e 's/<\/error_count>//g'`

if [[ ${error_count} == '' ]]; then
    error_count=0
fi

# To obtain the call count:
call_count=`curl -s -X GET "${PROTO}://api.newrelic.com/v2/applications/${APPID}/metrics/data.xml" \
    -H "X-Api-Key:${APIKEY}" -i \
    -d 'names[]=HttpDispatcher&values[]=call_count&summarize=true' | grep "<call_count>" |\
    sed -e 's/<call_count>//g' -e 's/<\/call_count>//g'`

# To obtain the average:
average=`curl -s -X GET "${PROTO}://api.newrelic.com/v2/applications/${APPID}/metrics/data.xml" \
    -H "X-Api-Key:${APIKEY}" -i \
    -d 'names[]=OtherTransaction/all&values[]=call_count&summarize=true' | grep "<call_count>" |\
    sed -e 's/<call_count>//g' -e 's/<\/call_count>//g'`

# Application Error Rate = 100 * Errors/all:error_count / (HttpDispatcher:call_count + OtherTransaction/all:call_count)
#echo -e $error_count $call_count $average
ERROR_RATE=$(echo "scale=9; 100 * ${error_count} / (${call_count} + ${average})" | bc | awk '{printf "%f", $0}' )

#result of fractional numbers comparison will be true(1) or false(0)
ANSWER=$(echo ${ERROR_RATE} '>=' 1 | bc -l )

if [[ ${ANSWER} = 1 ]]; then
        CHECK="FAILED"
        RETURN_PHRASE="ERROR RATE: ${ERROR_RATE}%"
            # additional check if it's .DK
        if [[ ${APPID} == "3310730" ]]; then
            CHECK="OK"
        fi
elif [[ ${ANSWER} = 0 ]]; then
        CHECK="OK"
        RETURN_PHRASE="ERROR RATE: ${ERROR_RATE}%"    
fi
}

# Some checks of integration services
function curl_check() {

URL=${ARG2}
PORT=${ARG3}
TO_CHECK=$4 #looks like this parameter is not supported

if [[ ${TO_CHECK} == "loginapi_check" ]]; then
    REQUEST_TYPE="POST"
    POST_PARAMETERS="-d FormName=fmLogin -d application=1 -d reff= \
                     -d tbUsername=monitoring_product -d tbPassword=TestPasswd \
                     -d retUrl=http://vegas.project.com/extLoginRedirect"
    ###RESPONSE_STRING="%{url_effective}"
    URL_EFFECTIVE=""
elif [[ ${TO_CHECK} == "F5irules_check" ]]; then
    REQUEST_TYPE="GET"
    POST_PARAMETERS=""
    URL_EFFECTIVE=""
else
    REQUEST_TYPE="GET"
    POST_PARAMETERS=""
    URL_EFFECTIVE=""
fi

if [[ ${PORT} == "443" ]]; then
    PROTO="https"
elif [[ ${PORT} == "80" ]]; then
    PROTO="http"
fi

ENDPOINT="${PROTO}://${URL}"   
###GET_SERVER_STATUS=`curl -s -o /dev/null -I -w "%{http_code}\\n" ${ENDPOINT} -o /dev/null`
GET_SERVER_STATUS=`curl -sL -w "%{http_code} ${URL_EFFECTIVE}\\n" -X ${REQUEST_TYPE} ${ENDPOINT} ${POST_PARAMETERS} -o /dev/null`

if [[ ${GET_SERVER_STATUS} -eq 200 ]]; then
    CHECK="OK"
    RETURN_PHRASE="${ENDPOINT} HTTP ${GET_SERVER_STATUS}"
else
    CHECK="FAILED"
    RETURN_PHRASE="${ENDPOINT} HTTP ${GET_SERVER_STATUS}"
fi
}

function ping_check() {

HOST_NAME=${ARG2}
#TIMEOUT=${ARG3}
#timeout in milliseconds

#GET_SERVER_STATUS=`/usr/sbin/fping -c1 -t${TIMEOUT} ${HOST_NAME} > /dev/null`
GET_SERVER_STATUS=`ping -c1 ${HOST_NAME} > /dev/null`

if  [[ $? -eq 0 ]]; then
    CHECK="OK" && RETURN_PHRASE="${HOST_NAME}"
else
    CHECK="FAILED" && RETURN_PHRASE="${HOST_NAME}"
fi

}

function oapi_resp_check() {

HOST_NAME=${ARG2}
REQ_ID=${ARG3}

echo ${HOST_NAME} ${REQ_ID}
# hosts passes to this script as string devided by ccomas, we need to parse string and save to array
# we use ${string//substring/replacement}
array_of_oapi_hosts=(${HOST_NAME//,/ })

echo "array length:" ${#array_of_oapi_hosts[@]}

for (( i=0; i<=${#array_of_oapi_hosts[@]}; i++ ))
    do
        #echo -e "${array_of_oapi_hosts[$i]}"
        OAPI_HOSTS=${array_of_oapi_hosts[$i]}

done

CHECK="OK" && RETURN_PHRASE="OGW hosts: ${OAPI_HOSTS}"

}

function cluster_nodes_check() {
TO_GREP=${ARG2}
JMX_PORT=${ARG3}
COUNT_WHEN_OK=$4
#TO_GREP='lbfprod-'
#wpl-dev10-

if [ -z "${JMX_PORT}" ]; then
    JMX_PORT="8999"
fi

if [ ${TO_GREP} == "wpl-dev10-" ]; then
    COUNT_WHEN_OK=2
elif [ ${TO_GREP} == "lbfperf-wpllbv-pub-por-" ]; then
    COUNT_WHEN_OK=10
elif [ ${TO_GREP} == "lbfprod-wpllbv-pub-por-" ]; then
    COUNT_WHEN_OK=10
fi

export JAVA_BIN="/opt/java/java/bin/java"
export JMX_JAR="/usr/lib64/nagios/plugins/jmxterm-1.0-alpha-4-uber.jar"

cmd=$(echo 'get -b JGroupsReplication:type=protocol,cluster=app-multi-vm-clustered,protocol=UNICAST Members' | ${JAVA_BIN} -jar ${JMX_JAR} -l localhost:${JMX_PORT} -v silent -n | grep -o ${TO_GREP} | wc -l)

if [ ${cmd} == ${COUNT_WHEN_OK} ]; then
    CHECK="OK" && RETURN_PHRASE="${cmd} nodes in my cluster"
else {
    CHECK="FAILED" && RETURN_PHRASE="only ${cmd} nodes in my cluster"
}
fi

}

# $@ NEED FOR FUNCTION CALL
$@

# OUTPUT FOR NAGIOS GENERATES HERE
if [[ $CHECK == "OK" ]]; then
        echo "SERVICE OK ${RETURN_PHRASE}"
        exit 0
elif [[ $CHECK == "FAILED" ]]; then
        echo "Service not working ${RETURN_PHRASE}"
        exit 2
else
        echo "Check failed"
        exit 3
fi