#!/bin/bash
ENVIRONMENT_FILE="environment.txt"
HEADER="Content-Type:application/json"

source ${ENVIRONMENT_FILE}
OLD_HOST=${HOST}
OLD_PORT=${PORT}
OLD_ECI=${ECI}
OLD_EID=${EID}
OLD_RID=${RID}
OLD_DOMAIN=${DOMAIN}
OLD_TYPE=${TYPE}
OLD_FUNCTION=${FUNCTION}

children=1
numTemps=0
name=

query=0
event=0

EVENT_URL="http://${HOST}:${PORT}/sky/event"
QUERY_URL="http://${HOST}:${PORT}/sky/cloud"


usage()
{
    echo "usage: sysinfo_page -q  [[[-f file ] [-i]] | [-h]]"
}


# Take care of all parameters
while [ "$1" != "" ]; do
    case $1 in
        -ch | --children )           shift
                                children=$1
                                ;;
        -q | --query )             
                                query=1
                                event=0
                                ;;
        -e | --event )            
                                event=1
                                query=0
                                ;;
        -d | --domain )             shift
                                OLD_DOMAIN=$1
                                ;;
        -t | --type )               shift
                                OLD_TYPE=$1
                                ;;
        -name | --name )            shift
                                name=$1
                                ;;
        -f | --function )            shift
                                FUNCTION=$1
                                ;;
        -nt | --numTemps )          shift
                                numTemps=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done


FULL_EVENT_URL="${EVENT_URL}/${ECI}/${EID}/${OLD_DOMAIN}/${OLD_TYPE}"
FULL_QUERY_URL="${QUERY_URL}/${ECI}/${RID}/${FUNCTION}?"

echo "Using url for EVENTS: "
echo ${FULL_EVENT_URL}
echo "Using url for QUERIES: "
echo ${FULL_QUERY_URL}
echo ""


#MAIN _________________________________________

if [ $event == 1 ] 
then
    if [ $OLD_TYPE == "new_sensor" ] 
    then
        # CREATES CHILDREN 
        for ((a=1; a <= $children ; a++))
        do
            curl --header ${HEADER} --request POST --data '{"sensor_id":"TEST'$a'"}' ${FULL_EVENT_URL}
        done
    fi
    if [ $OLD_TYPE == "unneeded_sensor" ]
    then
        curl --header ${HEADER} --request POST --data '{"sensor_id":"'$name'"}' ${FULL_EVENT_URL}
    fi
else
    if [ $FUNCTION == "temperatures" ]
    then
        curl --header ${HEADER} --data '{"sensor_id":"'$name'"}' ${FULL_QUERY_URL}
    fi
    if [ $FUNCTION == "showChildren" ]
    then
        curl --header ${HEADER} ${FULL_QUERY_URL}
    fi
    if [ $FUNCTION == "sensors" ]
    then
        curl --header ${HEADER} ${FULL_QUERY_URL}
    fi
fi

