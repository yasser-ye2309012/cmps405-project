#!/bin/bash

function f1() {
    # disk usage of home directory in KB and reverse sort
    du -k "$HOME" 2>/dev/null | sort -nr > /tmp/Disk_Usage.txt

    # cpu info
    lscpu | grep -E "(Model name:|Vendor ID:|^CPU\(s\):|Architecture:)" > /tmp/cpu_info.txt
    
    # all kernel info (sudo is needed because dmesg is restricted on Ubuntu)
    sudo dmesg | grep -E "(Memory|RAM|mem|memory|Out of memory|oom|swap|page allocation|sd[a-z]|sata|scsi|nvme|disk|block)" > /tmp/Messages_Log.txt
    
    # kernel messsages count (word count of the memory lines and of the disk lines)
    {
        echo "Memory words: $(grep -E "(Memory|RAM|mem|memory|Out of memory|oom|swap|page allocation)" /tmp/Messages_Log.txt | wc -w)"
        echo "Disk words: $(grep -E "(sd[a-z]|sata|scsi|nvme|disk|block)" /tmp/Messages_Log.txt | wc -w)"
    } > /tmp/Message_count.txt

    # compression
    timestamp=$(date +%d%H%M%S)
    backup_dir="$HOME/backup-f1/$timestamp"
    mkdir -p "$backup_dir"
    # -C /tmp so the paths are relative
    tar -cjf "$backup_dir/Phase1.tar.bz2" -C /tmp Disk_Usage.txt cpu_info.txt Messages_Log.txt Message_count.txt
}

function f2() {
    local timestamp dest

    # Ambiguous requirement: "Files with read and execute permissions for the owner only" interpreted as "the owner has read and execute permissions, but not write, permissions for other groups are ignored"
    timestamp=$(date +%y%m%d%H%M%S) || return 1
    dest="$HOME/backup-f2/$timestamp"

    mkdir -p "$dest" || return 1

    # ls /home -laR 2>/dev/null | grep '^-r-x'

    # The above line doesn't work since it only returns the file names and not the full path
    # first block in awk matches directories and replaces ':' with '/'
    # second block in awk matches actual file records with the permission requirement and \
    # prints only the file name next to the directory, example: /home/khaled/lab03/ex03/file_modes
    ls "$HOME" -laR 2> /dev/null |
    awk '
        /^\/home.*:$/ {
            dir = $0
            sub(/:$/, "/", dir)
            next
        }
        /^-r-x/ {
            name = $NF
            print dir name
        }
    ' |
    while IFS= read -r file; do
        target="$dest$file"

        mkdir -p "$(dirname "$target")" || continue
        cp -p "$file" "$target"
    done

    # chmod -R 400 "$dest" 

    # The above line doesn't work since directories will not be accessible. \
    # For directories to be accessible they need to have execute permissions \
    find "$dest" -type f -exec chmod 400 {} +
    find "$dest" -type d -exec chmod 500 {} +
    echo "$dest"
}

function f3() {
    dest="$1"
    # verification and reporting (only the current backup directory is checked)
    all_files=$(find "$dest" -type f | wc -l)
    bad_files=$(find "$dest" -type f ! -perm 400 | wc -l)

    echo "Number of files backed up: $all_files"
    echo "Size of backup directory: $(du -sh "$dest" | awk '{print $1}')"
    echo "Number of files NOT read-only for owner (errors): $bad_files"

    # report each wrong file as an error
    find "$dest" -type f ! -perm 400 | while IFS= read -r f; do
        echo "ERROR: $f is not read-only for the owner"
    done

    echo "End of execution, time: $(date +%H:%M:%S)"
}

f1
dest=$(f2)
f3 "$dest"

# "(Memory|RAM|mem|memory|Out of memory|oom|swap|page allocation)"
# "(sd[a-z]|sata|scsi|nvme|disk|block)"