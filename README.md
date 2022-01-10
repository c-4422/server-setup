# Server Setup Script
Script for setting up rootless podman on CentOS

I created this guided installer to help people get their own home servers up 
and running. I guess you could also use this for setting up infrastructure 
for a small business but keep in mind that this script has no warranty for
function or future support. Use the script at your own risk.

List of things this script does:

Step 1:
- Add selected user to sudo group.
- Install all necessary programs.
- Enable software services, verify sudo is enabled.
- Enable cockpit and Fail2ban.

Step 2:
- Modify kernel parameters so that port 80 is usable with rootless podman.
- Enable / Disable additional kernel parameters for added security.

Step 3:
- Configure folders for podman persistent storage.

Step 4:
- Configure systemd user settings.
- Configure podman to use fuse-fs.

Step 5:
- Configure pass password manager

Step 6:
- Configure automatic updates and backup service.

Step 7:
- Configure containers configuration folder.
- Download "master" Makefile for managing podman configurations

Step 8:
- Possibly add lsper alias to .bashrc

### Running Server Setup Script
1. Need to be a user that is in the sudo group
2. Download the latest version of the script from releases
3. Mark server-setup.sh as executable using
```
chmod +x server-setup.sh
```
4. Run server setup script and follow the guided prompts
```
./server-setup.sh
```
