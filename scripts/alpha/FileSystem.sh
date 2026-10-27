function f1() {
    du -sh /home | sort -hr > /tmp/Disk_Usage.txt
    lscpu | grep -E "(Model name:|Vendor ID:|^CPU\(s\):|Architecture:)" > /tmp/cpu_info.txt

}

function f2() {
    # Ambiguous requirement: "Files with read and execute permissions for the owner only" interpreted as "the owner has read and execute permissions, but not write, permissions for other groups are ignored"
    
}

function backup_home() {
    local timestamp dest

    timestamp=$(date +%y%m%d%H%M%S) || return 1
    dest="$HOME/$timestamp"

    mkdir -p "$dest" || return 1

    # first block in awk matches directories and replaces : with /
    # second block in awk matches actual file records with the permission requirement and \
    # prints only the file name next to the directory, example: /home/khaled/lab03/ex03/file_modes
    ls /home -laR 2>/dev/null |
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
}