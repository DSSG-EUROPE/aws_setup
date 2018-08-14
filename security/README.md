# Security

## Block SCP downloads!
We want to avoid users downloading data files through `scp`, but still let them transfer small files (scripts, etc) and have SSH access. We can achieve this by blocking traffic that exceeds a certain packet size.

iptables -I OUTPUT -p tcp --sport 22 -m length --length 1400:0xffff -m recent --name noscp --rdest --set 
iptables -I OUTPUT -p tcp --sport 22 -m length --length 1400:0xffff -m recent --name noscp --rdest --update --seconds 5 --hitcount 8 -j REJECT --reject-with tcp-reset

## Monitor log-in attempts
Running `last` shows the last attempted succesful log ins.
More interestingly, `lastb` shows the bad or unsuccessful log-ins - potentially adversarial attackers!

## Monitor sudo attempts
`/var/log/auth.log` stores unauthorized sudo attempts (grep for "user NOT in sudoers")
(When users without sudo access attempt to run sudo they will receive a message:
```
$user is not in the sudoers file.  This incident will be reported.
```

## Security through obscurity: port obfuscation
port 22 is the standard port to use for SSH connection. This is also the first port an attacker will attempt to connect to. To make it a little harder, consider setting it to a different port number.
REF:
- [sshd_config](https://www.ssh.com/ssh/sshd_config/)

## Block root login through SSH
Don't allow SSH login into the root user. In the `/etc/ssh/sshd_config` file, set `PermitRootLogin no`
(but first make sure you can log in as another user than has sudo access, otherwise you won't be able to use the root user again)
REF:
- [sshd_config](https://www.ssh.com/ssh/sshd_config/)

## Check the logs
The /var/log directory stores logs on various system components and activities.

`/var/log/apt/history.log` shows a history of the `apt` package manager usage.

`/var/log/kern.log` shows the kernel boot log

`/var/log/syslog` shows the kernel boot log as well as logs of other daemons like systemd, and programs like cloud-init, dhclient, pollinate, etc.
NB.1. If the machine boots into emergency mode, this will be mentioned in the `syslog`.
NB.2. This file can be viewed in the AWS web Console by right-clicking an EC2 instance ```>> Instance Settings >> Get System Log```
`/var/log/auth.log` stores unauthorized sudo attempts (grep for "user NOT in sudoers")
(When users without sudo access attempt to run sudo they will receive a message:
```
$user is not in the sudoers file.  This incident will be reported.
```

# journalctl
System logs can be navigated with the `journalctl` command.
You can search logs pertaning to specific users, processes, time periods, programs, priority (critical, emergency, alert etc.
cf. https://www.loggly.com/ultimate-guide/using-journalctl/
cf. https://www.digitalocean.com/community/tutorials/how-to-use-journalctl-to-view-and-manipulate-systemd-logs
~                                                                                                              
