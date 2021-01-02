/*
Authorization manager for Merlin
Forked from Rosuav/Yosemite

Run this (as root) to accept keys for sshfs. Once this is running, anyone with
HTTP access can connect to the share as follows:

$ wget Merlin/merlin_client
(If you fork this project, replace "Merlin" with your server's hostname)
$ chmod +x merlin_client
$ ./merlin_client

TODO: Make this more generic. It's currently specific to my own LAN.

To install client under systemd:
$ sudo ./merlin_client install

Setup:
* Create new account, create .ssh/authorized_keys, clean out everything else in ~ and mark it all read-only except authorized_keys itself
* Ensure that account has read-only access to /video

*/

void request(Protocols.HTTP.Server.Request req)
{
	switch (req->not_query)
	{
		//Return the script used for connecting.
		case "/merlin_client": req->response_and_finish((["data":sprintf(
#"#!/bin/bash
[ \"$1\" = \"install\" ] && [ -d /etc/systemd/system ] && {
	echo \"[Unit]
Description=Merlin's Video Library

[Service]
# The user, path, and X display are derived at installation time
# from the attributes of the client script. Reinstall to reset them.
Environment=DISPLAY=$DISPLAY LANG=$LANG
User=`stat -c %%u $0`
ExecStart=`readlink -e $0`
ExecReload=`readlink -e $0` reconnect
# If the network isn't available yet, restart until it is.
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
\" >/etc/systemd/system/merlin.service
	systemctl --system daemon-reload
	systemctl enable merlin.service
	echo Installed as merlin.service.
	systemctl start merlin.service
	exit
}
cd
# Ensure we have a keypair to use
[ -d .ssh ] || mkdir .ssh
[ -f .ssh/id_rsa.pub ] || ssh-keygen -f .ssh/id_rsa -N '' -q
# Try to make the mount point, if possible. (This really ought to be
# somewhere else, but I don't want to break backward compat on the LAN.)
[ -d /video ] || mkdir /video 2>/dev/null || { sudo mkdir /video 2>/dev/null && sudo chown $USER: /video; }
# Try to authenticate with the server, logging to .merlin_authority
# If the authentication fails or is revoked, remove that file to re-attempt.
[ -f .merlin_authority ] || wget %s/.merlin_authority --post-file .ssh/id_rsa.pub -q
sshfs yosemite@%<s:/video/ /video -oStrictHostKeyChecking=no -ononempty
cd /video
[ \"$1\" = \"reconnect\" ] && exit 0
python3 Yosemite.py
", req->request_headers->host || "Merlin")])); break;
		//Accept client public key for authentication.
		case "/.merlin_authority": if (req->body_raw!="")
		{
			//TODO: Check for duplicates (maybe by ignoring the key and
			//just replacing anything with the same "user@host" tail).
			Stdio.append_file("/home/merlin/.ssh/authorized_keys",String.trim_all_whites(req->body_raw)+"\n");
			req->response_and_finish((["data":"Authenticated at "+ctime(time())]));
			break;
		}
		default: req->response_and_finish((["data":"Not found.","error":404]));
	}
}

int main()
{
	Protocols.HTTP.Server.Port(request, 80);
	//TODO: Drop privileges
	return -1;
}
