#!/bin/bash
# =============================================================
# SysInfo.sh - BETA VM, Task 3: System Information Report
# Collects information about this machine (disk, CPU, memory,
# installed applications, network interface cards) and writes
# everything into ONE report file whose name contains the host
# name, the date and the time.
# The report is ready to be sent to ALPHA (Remote.sh uploads it).
# Usage: ./SysInfo.sh
# Report: ~/SysInfo_<hostname>_<YYYYMMDD>_<HHMMSS>.txt
# =============================================================

# --- Variables -------------------------------------------------
HOST=$(hostname)                          # name of this machine (beta)
STAMP=$(date '+%Y%m%d_%H%M%S')            # date and time, e.g. 20261027_153045
REPORT="$HOME/SysInfo_${HOST}_${STAMP}.txt"   # the report file (timestamped)

# --- Function: print a section title ---------------------------
# $1 = the title text
title () {
    echo
    echo "=============================================="
    echo "  $1"
    echo "=============================================="
}

# --- Function: write the whole report --------------------------
collect () {
    echo "SYSTEM INFORMATION REPORT"
    echo "Host name : $HOST"
    echo "Date      : $(date)"
    echo "User      : $(whoami)"

    # ---- 1. Disk ----
    title "1. DISK INFORMATION"
    echo "--- Disk usage per file system (df -h) ---"
    df -h
    echo
    echo "--- Disks and partitions (lsblk) ---"
    lsblk

    # ---- 2. CPU ----
    title "2. CPU INFORMATION"
    lscpu                                  # architecture, cores, model name ...

    # ---- 3. Memory ----
    title "3. MEMORY INFORMATION"
    echo "--- RAM and swap (free -h) ---"
    free -h
    echo
    echo "--- First lines of /proc/meminfo ---"
    head -5 /proc/meminfo

    # ---- 4. Installed applications ----
    title "4. INSTALLED APPLICATIONS"
    # dpkg -l lists packages; lines starting with "ii" are installed ones
    COUNT=$(dpkg -l | grep '^ii' | wc -l)  # count the lines = number of packages
    echo "Number of installed packages: $COUNT"
    echo
    echo "--- Installed packages (name, version, description) ---"
    dpkg -l | grep '^ii'

    # ---- 5. Network interface cards ----
    title "5. NETWORK INTERFACE CARDS"
    echo "--- Interfaces and IP addresses (ip addr) ---"
    ip addr show
    echo
    echo "--- Hardware network cards (lspci) ---"
    if which lspci > /dev/null; then              # only if lspci exists
        lspci | grep -i ethernet           # show only the network card lines
    else
        echo "lspci is not installed (sudo apt install pciutils)"
    fi

    echo
    echo "===== End of report ====="
}

# --- Run: everything the function prints goes into the report --
collect > "$REPORT"

# --- Tell the user where the report is ------------------------
echo "Report created: $REPORT"
echo "Size and date of the file:"
ls -l "$REPORT"
echo
echo "Sections written in the report:"
grep "^  [0-9]\." "$REPORT"       # show only the 5 section titles
exit 0
