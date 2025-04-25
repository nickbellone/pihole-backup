#!/bin/bash

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

BACKUP_DIR="" # Backup Location
REMOTE_IP=""
REMOTE_USER=""
REMOTE_PORT=""
REMOTE_PATH="" # Remote Location
LOG_DIR="$BACKUP_DIR/logs"
LOG_FILE="$LOG_DIR/backup_$(date '+%Y%m%d').log"
MAX_BACKUPS=4

mkdir -p "$LOG_DIR"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo "$1"
}

log_message "Starting PiHole backup process"

# Create PiHole backup
if pihole-FTL --teleporter; then
    log_message "PiHole backup created successfully"
else
    log_message "Error: PiHole backup creation failed"
    exit 1
fi

# Find the most recent backup file
LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/*.zip 2>/dev/null | head -n1)
if [ -z "$LATEST_BACKUP" ]; then
    log_message "Error: No backup file found"
    exit 1
fi

# Sync most recent backup
log_message "Starting rsync of latest backup to remote server"
if rsync -av -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $REMOTE_PORT" "$LATEST_BACKUP" \
    "$REMOTE_USER@$REMOTE_IP:$REMOTE_PATH/"; then
    log_message "Rsync of latest backup completed successfully"
else
    log_message "Error: Rsync failed"
    exit 1
fi

# Clean up locally
log_message "Cleaning up old backups locally"
cd "$BACKUP_DIR" || exit
if ls -t *.zip 2>/dev/null | tail -n +3 | xargs -r rm -- ; then
    log_message "Old backups cleaned up successfully"
else
    log_message "Warning: No old backups to clean up or cleanup failed"
fi

# Retain last two backups on remote server
log_message "Cleaning up old backups on remote server"
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_IP" "cd $REMOTE_PATH && \
    ls -t *.zip 2>/dev/null | tail -n +3 | xargs -r rm --" || \
    log_message "Warning: Remote cleanup failed"

log_message "Backup process completed"