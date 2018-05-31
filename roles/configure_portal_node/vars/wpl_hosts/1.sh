#!/usr/bin/env bash


dirs=$(find . -maxdepth 1 -type d);

for i in $dirs; do

    # find host dirs
    find $i/application/ -maxdepth 1 -type d -name "application" >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            #echo "Host with only node_config.yml file: " $i;

            # find wpl3 hosts with uncompleted configuration
            cat $i/node_config.yml | grep  "wpl_version: wpl3" > /dev/null
                if [ $? -eq 0 ]; then
                    #echo "WPL3 host: " $i
                    echo $i
                fi
        fi
done
