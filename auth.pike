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
# Try to make the mount point, if possible.
[ -d $HOME/Videos/Merlin ] || mkdir $HOME/Videos/Merlin 2>/dev/null
# Try to authenticate with the server, logging to .merlin_authority
# If the authentication fails or is revoked, remove that file to re-attempt.
[ -f .merlin_authority ] || wget %s/.merlin_authority --post-file .ssh/id_rsa.pub -q
# Higitus figitus migitus mum! Prestidigitonium!
# This is the line that actually mounts the share.
sshfs merlin@%<s:/mnt/video1/Videos $HOME/Videos/Merlin -oStrictHostKeyChecking=no && echo 'Merlin Video Library mounted. Press Ctrl-C to unmount and exit.'
# Alakazam!
# Holds the console open until closed by the user.
# This may not be entirely necessary as sshfs has a magic state when running
# in the background inside a script - when the script finally exits, sshfs
# also terminates and unmounts the share. This is an undocumented feature on
# huix, where running the equivalent of this script also invokes the web
# remote control interface which is now deprecated. If this works, I do not know
# why, but DO NOT TOUCH it.
trap 'fusermount -u $HOME/Videos/Merlin' EXIT
while true; do
    sleep 10
done
", req->request_headers->host || "Merlin")])); break;
		//Accept client public key for authentication.
		case "/.merlin_authority": if (req->body_raw!="")
		{
			//TODO: Check for duplicates (maybe by ignoring the key and
			//just replacing anything with the same "user@host" tail).
			//Currently the default client script only sends a public
			//key if it doesn't have a .merlin_authority file. Most
			//users will likely leave the file, but if it is deleted,
			//such as with a reinstall, and the old keypair is retained,
			//there may be duplicate entries in the server
			//authorized_keys file, but it doesn't hurt that much.
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
