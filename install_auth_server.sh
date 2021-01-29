#!/bin/bash
# Install SystemD service for the authorization server
instl ()
{ echo "[Unit]
Description=Archimedes Authorization Server
After=network.target

[Service]
Type=simple
WorkingDirectory=`pwd`
ExecStart=/usr/bin/env pike `pwd`/auth.pike
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
" >/etc/systemd/system/merlin_auth.service
systemctl --system daemon-reload
	systemctl enable merlin_auth.service
	echo Installed as merlin_auth.service.
	systemctl start merlin_auth.service
}

if [[ `id -u` -ne 0 ]] ; then
	echo "This installer must be run using sudo."
	exit 1
fi
read -p "This will install auth.pike as a system service. Continue? [y/n] " -r
if [[ $REPLY =~ ^[Yy] ]] ; then
	instl
else
	echo "Aborted."
fi
