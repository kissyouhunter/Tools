#!/bin/bash

# Root required
if [ $(id -u) != "0" ];
then
        echo -e "Error: You need to be root to uninstall the MyNodeQuery agent\n"
        echo -e "The agent itself is NOT running as root but instead under its own non-privileged user\n"
        exit 1
fi

# Attempt to delete agent
if [ -f /etc/mynodequery/mynq-agent.sh ]
then
        # Remove agent dir
        rm -Rf /etc/mynodequery

        # Remove cron entry and user
        if id -u mynodequery >/dev/null 2>&1
        then
                (crontab -u mynodequery -l | grep -v "/etc/mynodequery/mynq-agent.sh") | crontab -u mynodequery -
                if [ -n "$(command -v userdel)" ]
                then
                        userdel mynodequery
                else
                        deluser mynodequery
                fi
        else
                (crontab -u root -l | grep -v "/etc/mynodequery/mynq-agent.sh") | crontab -u root -
        fi
        echo "MyNodeQuery agent and cron jobs removed successfully."
else
        echo "MyNodeQuery agent not found."
fi
