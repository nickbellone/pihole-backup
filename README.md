Shell script that backs up Pihole configuration (v6.x) to remote location.
Specifically in my environment, Pihole is configured on a VM on an Unraid server and sends the backup file to an rsync docker container also running on the Unraid server. E.g.
Remote port: 5000
Remote location: /backuppihole (container path)
Backup location: /your/setup/here
