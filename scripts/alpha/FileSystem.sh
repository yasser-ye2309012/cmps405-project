function f1() {
    # disk usage of home directory in KB and reverse sort
    du -s /home | sort -hr > /tmp/Disk_Usage.txt

    # cpu info
    lscpu | grep -E "(Model name:|Vendor ID:|^CPU\(s\):|Architecture:)" > /tmp/cpu_info.txt
    
    # all kernel info
    dmesg | grep -E "(Memory|RAM|mem|memory|Out of memory|oom|swap|page allocation|sd[a-z]|sata|scsi|nvme|disk|block)" > /tmp/Messages_Log.txt
    
    # kernel messsages count
    echo 'Memory lines: ' | cat >> /tmp/Message_count.txt
    grep -E "(Memory|RAM|mem|memory|Out of memory|oom|swap|page allocation)" < /tmp/Messages_Log.txt | wc -l | cat > /tmp/Message_count.txt
    echo 'v Disk lines: ' | cat >> /tmp/Message_count.txt
    grep -E "(sd[a-z]|sata|scsi|nvme|disk|block)" < /tmp/Messages_Log.txt | wc -l | cat >> /tmp/Message_count.txt

    # compression
    timestamp=$(date +%d%H%M%S)
    backup_dir="$HOME/backup-f1/$timestamp"
    mkdir -p "$backup_dir"
    tar -cjf "$backup_dir/Phase1.tar.bz2" /tmp/Disk_Usage.txt /tmp/cpu_info.txt /tmp/Messages_Log.txt /tmp/Message_count.txt
}

function f2() {
    # Ambiguous requirement: "Files with read and execute permissions for the owner only" interpreted as "the owner has read and execute permissions, but not write, permissions for other groups are ignored"
    local timestamp dest

    timestamp=$(date +%y%m%d%H%M%S) || return 1
    dest="$HOME/backup-f2/$timestamp"

    mkdir -p "$dest" || return 1

    # ls /home -laR 2>/dev/null | grep '^-r-x'

    # The above line doesn't work since it only returns the file names and not the full path
    # first block in awk matches directories and replaces ':' with '/'
    # second block in awk matches actual file records with the permission requirement and \
    # prints only the file name next to the directory, example: /home/khaled/lab03/ex03/file_modes
    ls /home -laR 2> /dev/null |
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
}

function f3() {
    # verification and reporting
    all_files=$(find ~/backup-f2/ -type f | wc -l)
    valid_files=$(find ~/backup-f2/ -type f -exec ls -la {} + | grep -E '^-r--------' | wc -l) || return 1
    echo "Number of files backed up: $all_files"
    echo "Size of backup directory: $(du -sh ~/backup-f2/ | awk '{print $1}')" 
    echo "Number of files not matching permission requirement (errors): $((all_files - valid_files))"

    echo "End of execution, time: $(date +%H:%M:%S)"
}

f1
f2
f3

# "(Memory|RAM|mem|memory|Out of memory|oom|swap|page allocation)"
# "(sd[a-z]|sata|scsi|nvme|disk|block)"