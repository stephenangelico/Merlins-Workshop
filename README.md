Simple SSHFS wrapper for movie/disk server

If you want to have a Linux NAS for music, movies or any Write Once Read Many
collection, and you want to access it with your normal file manager, then SSHFS
could be the tool for you! But suppose you want grant read-only access to your
family or housemates, and you don't want them to have to enter a password each
time... the configuration can be a little involved. This project gives a few
helpers, but most importantly, this guide should walk you through everything.

Use ONLY on LAN, and be sure you trust those on your LAN.

Requires [Pike 7.8][1] or greater.

Setup:
======


You will need two user accounts on the server - one with read/write access, to
add new content, and one with read-only access that most people will use.
These instructions assume a functional Linux system with [Pike][1] installed.

These instructions will set up the mount point, user accounts, authentication
keys and automatic reception of keys, as well as strict access control for the
read-only user.

- Clone this repository and enter the directory:

  ```
  git clone https://github.com/stephenangelico/Merlins-Workshop.git
  cd Merlins-Workshop
  ```

- If mount point is not to be on the boot drive, format the drive (if it's not
  already formatted) with whatever tool you choose (good GUI tools include GNOME
  Disks and GParted), and add the drive to `/etc/fstab`:

  ```
  sudo -e /etc/fstab
  ```

  Adjust the following line according to your hardware before appending:

  ```
  UUID=2e1da9dc-b8ec-4fa2-9d56-424f798c7628	/mnt/video1	ext4	rw,relatime	0	2
  ```

  Replace the UUID with the one from your drive - either copy it from the tool
  you used to create it, or use `sudo blkid` to find it from a list.
  Replace the path with wherever you want the drive to be mounted.
  If you formatted the drive as something other than ext4, replace `ext4` with
  the format you chose.

- Create drive mount point:

  ```
  sudo mkdir /mnt/video1
  ```

- Mount drive (if applicable):

  ```
  sudo mount /mnt/video1
  ```

- Create content folder, owned by primary user:

  ```
  sudo mkdir /mnt/video1/Videos
  sudo chown 1000: /mnt/video1/Videos
  chmod -R 755 /mnt/video1/Videos
  ```

- Start copying content at your leisure.

- Create new read-only account:

  ```
  sudo adduser merlin # Set a password but no other fields matter
  su merlin
  ```

- Create .ssh/authorized_keys for the new user:

  ```
  touch ~/.ssh/authorized_keys
  ```

- Close session as read-only user by either typing `exit` or pressing `Ctrl-D`.

- Check SSH config:

  - Ensure that this line is in `/etc/ssh/sshd_config`:

    ```
    Include /etc/ssh/sshd_config.d/*.conf
    ```

  - Adjust `merlin.conf` as necessary and copy to `/etc/ssh/sshd_config.d/`:

    ```
    sudo cp merlin.conf /etc/ssh/sshd_config.d/
    ```

  - Restart SSH daemon service:

    ```
    sudo systemctl restart sshd.service
    ```

- Lock password for read-only user:

  ```
  sudo usermod -U merlin
  ```

- Set read-only user's shell to a not-shell:

  ```
  sudo usermod -s /bin/true merlin
  ```

- Install `auth.pike` as SystemD service:

  ```
  sudo ./install_auth_server.sh
  ```

- To test that everything works, run these on the client:

  ```
  wget wget Merlin/merlin_client
  chmod +x merlin_client
  ./merlin_client
  ```

  If you get a message that the library is mounted, it worked! Check to see if
  there's anything in `/home/[user]/Videos/Merlin` - if you see what you loaded
  onto the share, you're done!


Licence
=======

Made available under the MIT license.

Copyright (c) 2020, Stephen Angelico

`auth.pike` forked from Rosuav/Yosemite, Copyright (c) 2011-2013, Chris Angelico

Permission is hereby granted, free of charge, to any person obtaining a copy of 
this software and associated documentation files (the "Software"), to deal in 
the Software without restriction, including without limitation the rights to 
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
of the Software, and to permit persons to whom the Software is furnished to do 
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
SOFTWARE.

[1]: https://pike.lysator.liu.se/download/ "Download Pike"
