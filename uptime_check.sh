#!/bin/bash

# Create log file if it does not exists
if [ -e "/var/log/uptime.log" ]; then
    echo "***** File already exists *****"
else
    # Create the file if it doesn't exist
    sudo touch /var/log/uptime.log && sudo chmod 666 /var/log/uptime.log || exit 1
    echo "***** Log file created and permision updated successfully *****"
fi

# Log the server's uptime to the file
uptime >> /var/log/uptime.log || exit 1
echo "***** Uptime loged successfully *****"
