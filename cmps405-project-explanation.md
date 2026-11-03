# CMPS 405 Project Explanation

## 1. Overall project architecture

The project uses two Ubuntu VMs:

| VM | Role | Main responsibilities |
|---|---|---|
| **ALPHA** | Server | Users, MySQL, SSH, FTP, Apache, central logging, C program |
| **BETA** | Client | Connectivity tests, system reports, remote access, log forwarding |

The normal execution order is:

1. Configure both VMs and networking.
2. Run `Users.sh` and `Install.sh` on ALPHA.
3. Run `Connectivity.sh` and `SysInfo.sh` on BETA.
4. Configure `LogServer.sh` on ALPHA.
5. Configure `LogClient.sh` on BETA.
6. Run `Remote.sh` from BETA.
7. Run `Search.sh`, `Network.sh`, and `FileSystem.sh` on ALPHA.
8. Compile and run `part-2.c` on ALPHA.

All shell scripts use Bash. They rely heavily on:

- `$variable` — variable expansion
- `$(command)` — command substitution
- `$?` — previous command’s exit status
- `>` — overwrite a file
- `>>` — append to a file
- `2>/dev/null` — discard errors
- `2>&1` — redirect errors to normal output
- `|` — pipe one command into another
- `&&` / `||` — conditional execution
- functions — reusable blocks of commands

The shell syntax checks successfully. The C program compiles with `gcc -Wall -Wextra`, with one warning because `argc` is not used.

---

# 2. ALPHA scripts

## `scripts/alpha/Users.sh`

### Purpose

Creates ten accounts named:

```text
user1, user2, ..., user10
```

Each account receives:

- A home directory
- `/bin/bash` as its shell
- A password
- Membership in the `sudo` group

### Main variables

```bash
TOTAL=10
created=0
skipped=0
```

`TOTAL` controls how many users are created. The counters are used in the final summary.

The password assignment is hidden in the repository display because it is sensitive. Conceptually, the script defines a password variable and later uses it with:

```bash
echo "$user:$PASSWORD" | chpasswd
```

The password should not be committed to a public repository.

### Root check

```bash
if [ "$EUID" -ne 0 ]; then
```

`EUID` is the effective user ID. Root has ID `0`.

The script stops unless executed using:

```bash
sudo ./Users.sh
```

This is necessary because `useradd`, `chpasswd`, and `usermod` require administrative privileges.

### User creation loop

```bash
for i in $(seq 1 "$TOTAL"); do
    user="user$i"
```

This generates the names `user1` through `user10`.

The script checks whether a user already exists:

```bash
if id "$user" &>/dev/null; then
```

`id` succeeds if the account exists. `&>/dev/null` hides the command’s output.

If the account exists, the script reports it and uses:

```bash
continue
```

to skip to the next user.

Otherwise:

```bash
useradd -m -s /bin/bash "$user"
```

- `-m` creates `/home/userX`
- `-s /bin/bash` assigns Bash as the login shell

The password is assigned using:

```bash
echo "$user:$PASSWORD" | chpasswd
```

`chpasswd` reads input in the format:

```text
username:password
```

Finally:

```bash
usermod -aG sudo "$user"
```

- `-a` means append
- `-G sudo` adds the user to the sudo group

### Verification

The second loop uses:

```bash
getent passwd "$user"
groups "$user"
```

`getent passwd` displays the account database entry, including UID, home directory, and shell.

`groups` confirms that the user belongs to `sudo`.

### Important explanation

The script is designed to be safely executed twice. On the first run, it creates the users. On the second run, it prints that they already exist instead of failing.

---

## `scripts/alpha/Install.sh`

### Purpose

Installs and configures:

- MySQL
- OpenSSH
- vsftpd
- Apache

It also:

- Updates the package database
- Upgrades packages
- Enables services at boot
- Displays service status
- Logs errors to `Installation.log`

### Root and non-interactive mode

```bash
if [ "$EUID" -ne 0 ]; then
```

The script requires root privileges.

```bash
export DEBIAN_FRONTEND=noninteractive
```

This prevents package installation from asking interactive questions.

### Error logging

```bash
LOG="Installation.log"
errors=0
```

The `run` function wraps commands:

```bash
run() {
    local desc="$1"
    shift
    "$@" 2>>"$LOG"
    local rc=$?
```

The first argument is a human-readable description. `shift` removes it, leaving the actual command.

For example:

```bash
run "Installing MySQL server" $APT install mysql-server
```

The command’s standard error is appended to the log.

`$?` contains the command’s exit status:

- `0` means success
- Any non-zero value means failure

Failures increment the `errors` counter.

### Package operations

```bash
APT="apt-get -y -qq -o DPkg::Lock::Timeout=60"
```

This means:

- `-y` automatically answers yes
- `-qq` reduces output
- `DPkg::Lock::Timeout=60` waits up to 60 seconds if another package process has the lock

The script runs:

```bash
apt-get update
apt-get upgrade
```

Then installs MySQL, SSH, FTP, and Apache.

### Services

```bash
systemctl restart mysql
systemctl daemon-reload
```

`systemctl restart mysql` restarts MySQL.

`daemon-reload` makes systemd reread service configuration files. It does not reboot the machine.

The script enables services:

```bash
systemctl enable "$svc"
```

Enabling a service makes it start automatically during boot.

The status loop displays:

```bash
systemctl is-enabled "$svc"
systemctl is-active "$svc"
systemctl status "$svc"
```

The script finally displays the last 20 lines of `Installation.log`.

---

## `scripts/alpha/Search.sh`

### Purpose

Finds files larger than 1 MB in the current user’s home directory.

It creates `bigfile` containing:

- Search date
- Number of matching files
- File details

If the report is non-empty, it emails it using `msmtp`.

### Searching

```bash
find "$HOME" -type f -size +1M -exec ls -lh {} \;
```

Meaning:

- `find "$HOME"` searches from the user’s home directory
- `-type f` restricts results to regular files
- `-size +1M` selects files larger than 1 MB
- `-exec ls -lh {} \;` prints human-readable information for each file

Errors such as permission-denied messages are discarded:

```bash
2>/dev/null
```

The output is stored in:

```text
bigfile.tmp
```

### Counting

```bash
COUNT=$(wc -l < "$TMP")
```

Each matching file produces one line, so the number of lines equals the file count.

### Creating the report

If at least one file exists:

```bash
echo "Search date: ..." > bigfile
echo "Number of files..." >> bigfile
cat "$TMP" >> bigfile
```

The first `>` overwrites the file. The later `>>` operations append.

If no files are found:

```bash
> "$BIGFILE"
```

This creates an empty file or clears an existing one.

### Email section

```bash
if [ -s "$BIGFILE" ]; then
```

`-s` checks whether the file exists and has a size greater than zero.

The script checks for `msmtp`:

```bash
which msmtp
```

It then creates email headers:

```text
To:
From:
Subject:
```

A blank line separates the headers from the message body, as required by email format.

Finally:

```bash
msmtp "$ADMIN" < "$MAIL"
```

The email file is passed to `msmtp` through standard input.

### Important issue

The administrator email address is hardcoded in the script rather than read from `config.txt`. A better design would use a configuration variable so personal email addresses are not embedded in source code.

---

## `scripts/alpha/Network.sh`

### Purpose

Checks ALPHA’s network configuration and connectivity.

It displays:

1. Network interfaces
2. Routing table
3. Hostname
4. DNS configuration
5. DNS lookup
6. Traceroute to Google
7. Ping results

Everything is displayed and saved to `network.log`.

### `check_tool` function

```bash
check_tool ifconfig net-tools
```

The first argument is the command to check. The second is the package containing it.

```bash
command -v "$1"
```

`command -v` checks whether the command exists in the system PATH.

If missing, the script runs:

```bash
sudo apt-get update
sudo apt-get install -y "$2"
```

### Network diagnostic commands

```bash
ifconfig
```

Displays network interfaces and IP addresses.

```bash
route -n
```

Displays the routing table. `-n` prevents DNS name resolution and shows numeric addresses.

```bash
hostname
```

Displays the machine name.

```bash
cat /etc/resolv.conf
nslookup google.com
```

The first shows configured DNS servers. The second tests DNS resolution.

```bash
traceroute -m 15 -w 2 google.com
```

- `-m 15` limits the trace to 15 hops
- `-w 2` waits at most two seconds per response

```bash
ping -c 4 google.com
```

`-c 4` sends exactly four packets. Without it, `ping` would continue indefinitely.

### Logging

```bash
run_all 2>&1 | tee "$LOG"
```

This is important:

- `2>&1` combines errors with normal output
- `tee` displays the output and writes it to `network.log`

---

## `scripts/alpha/FileSystem.sh`

This file contains three functions: `f1`, `f2`, and `f3`.

### Function `f1`

#### Disk usage

```bash
du -k "$HOME" | sort -nr > /tmp/Disk_Usage.txt
```

- `du -k` reports disk usage in kilobytes
- `sort -n` sorts numerically
- `-r` reverses the order
- Output is saved to `/tmp/Disk_Usage.txt`

#### CPU information

```bash
lscpu | grep -E "(Model name:|Vendor ID:|^CPU\(s\):|Architecture:)"
```

Only these CPU fields are selected:

- Architecture
- Number of CPUs
- Model name
- Vendor ID

#### Kernel messages

```bash
sudo dmesg | grep -E "(Memory|RAM|mem|...|disk|block)"
```

`dmesg` displays kernel messages. `sudo` is needed because modern Ubuntu restricts access.

The `grep -E` expression attempts to select memory, storage, disk, SATA, SCSI, NVMe, and swap-related messages.

#### Word count

The script separately counts memory-related and disk-related words using:

```bash
grep ... /tmp/Messages_Log.txt | wc -w
```

The result is stored in `/tmp/Message_count.txt`.

#### Compression

```bash
timestamp=$(date +%d%H%M%S)
backup_dir="$HOME/backup-f1/$timestamp"
mkdir -p "$backup_dir"
tar -cjf "$backup_dir/Phase1.tar.bz2" -C /tmp ...
```

The timestamp format is:

```text
day hour minute second
```

For example:

```text
30055503
```

`tar -cjf` means:

- `-c` create archive
- `-j` use bzip2 compression
- `-f` specify filename

`-C /tmp` makes the archive store relative filenames instead of full `/tmp/...` paths.

The script archives four files, including `Message_count.txt`.

### Function `f2`

This function searches the home directory for files whose owner permissions begin with:

```text
-r-x
```

That means the owner has read and execute permissions but not write permission.

The script uses:

```bash
ls "$HOME" -laR
```

to recursively list files, then processes the output with `awk`.

The `awk` code remembers the current directory and reconstructs full paths.

Each selected file is copied into:

```text
$HOME/backup-f2/<timestamp>
```

The destination preserves the original absolute path underneath the backup directory.

For example, a source file such as:

```text
/home/student/test.txt
```

may become:

```text
/home/student/backup-f2/261102223000/home/student/test.txt
```

The script then applies:

```bash
find "$dest" -type f -exec chmod 400 {} +
find "$dest" -type d -exec chmod 500 {} +
```

Permission meanings:

- `400` — owner can read only
- `500` — owner can read and execute the directory

Directories need execute permission so they can be entered and searched.

The function prints the backup directory path. The caller captures it:

```bash
dest=$(f2)
```

### Important limitation

Parsing `ls` output is fragile when filenames contain spaces, tabs, or unusual characters. A more robust design would use `find` with null-separated output.

### Function `f3`

This verifies the backup.

```bash
all_files=$(find "$dest" -type f | wc -l)
```

Counts all regular files.

```bash
bad_files=$(find "$dest" -type f ! -perm 400 | wc -l)
```

Counts files whose permissions are not exactly `400`.

It prints:

- Number of files
- Backup size
- Number of incorrectly protected files
- Each incorrect file
- Completion time

The expected error count is zero.

### Overall execution

```bash
f1
dest=$(f2)
f3 "$dest"
```

The functions execute in sequence:

1. Create system information files and archive them.
2. Find and copy matching files.
3. Verify the backup.

---

## `scripts/alpha/LogServer.sh`

### Purpose

Configures ALPHA as a central `rsyslog` server.

It receives logs from BETA over:

- UDP port 514
- TCP port 514

Logs are stored using the sender hostname:

```text
/var/log/remote/<hostname>/<hostname>.log
```

### Configuration variables

```bash
BETA_IP="${1:-192.168.153.11}"
```

Uses the first command-line argument, or a default IP if none is supplied.

Other variables identify:

- Remote log directory
- rsyslog configuration file
- logrotate configuration file
- Setup log

### Output logging

```bash
exec > >(tee -a "$SETUP_LOG") 2>&1
```

This redirects all later output:

- To the terminal
- Appended to `/var/log/logserver_setup.log`

### rsyslog configuration

The script creates:

```text
/etc/rsyslog.d/10-remote.conf
```

It loads:

```text
imudp
imtcp
```

These are rsyslog input modules.

It creates UDP and TCP listeners on port 514:

```text
input(type="imudp" port="514" ruleset="remote")
input(type="imtcp" port="514" ruleset="remote")
```

The template:

```text
/var/log/remote/%HOSTNAME%/%HOSTNAME%.log
```

creates a separate directory and file for each sending host.

The `stop` instruction prevents remote messages from also being written to ALPHA’s normal local log.

### Validation

```bash
rsyslogd -N1
```

Checks the rsyslog configuration without starting the service.

The service is restarted only after validation succeeds.

### Firewall

The order matters:

```bash
ufw allow 22/tcp
ufw allow from "$BETA_IP" ...
ufw --force enable
```

SSH is allowed before enabling UFW. Otherwise the administrator could enable the firewall and lose SSH access.

Port 514 is allowed only from BETA, for both UDP and TCP.

HTTP port 80 is also allowed because BETA must access ALPHA’s Apache page.

### Testing

The script uses:

```bash
logger -n 127.0.0.1 -P 514 -d ...
logger -n 127.0.0.1 -P 514 -T ...
```

- `-d` sends UDP
- `-T` sends TCP
- `-n` specifies the destination
- `-P` specifies the port

It then searches the expected remote log file for the generated test tag.

### Log rotation

The generated logrotate configuration specifies:

```text
daily
rotate 7
compress
```

This means logs rotate daily and seven old copies are retained.

The `postrotate` command tells rsyslog to reopen its files after rotation.

---

# 3. BETA scripts

## `scripts/beta/Connectivity.sh`

### Purpose

Pings ALPHA once and appends the result to:

```text
/tmp/SecondVM.txt
```

The script itself performs one test. Repetition is handled by cron.

Example cron entry:

```text
*/5 * * * * /path/to/Connectivity.sh
```

The five cron fields mean:

```text
minute hour day-of-month month day-of-week
```

`*/5` means every five minutes.

### Ping logic

```bash
output=$(ping -c 1 -W 2 "$TARGET" 2>&1)
status=$?
```

- `-c 1` sends one packet
- `-W 2` waits two seconds for a response
- Both normal output and errors are captured

The exit status determines:

```text
REACHABLE
```

or:

```text
UNREACHABLE
```

The result is appended using `>>`, so previous tests remain in the file.

---

## `scripts/beta/SysInfo.sh`

### Purpose

Creates one timestamped system information report on BETA.

Example:

```text
/home/user/SysInfo_beta_20261027_153045.txt
```

### Sections

The `collect` function writes:

1. Disk information
2. CPU information
3. Memory information
4. Installed applications
5. Network interface information

### Disk

```bash
df -h
lsblk
```

- `df -h` shows filesystem usage
- `lsblk` shows disks and partitions

### CPU

```bash
lscpu
```

Displays CPU architecture, cores, model, and related details.

### Memory

```bash
free -h
head -5 /proc/meminfo
```

`free -h` shows RAM and swap. `/proc/meminfo` provides kernel memory statistics.

### Installed applications

```bash
dpkg -l | grep '^ii'
```

Ubuntu marks installed packages with the status `ii`.

The count is calculated using:

```bash
dpkg -l | grep '^ii' | wc -l
```

### Network interfaces

```bash
ip addr show
```

Displays interfaces and IP addresses.

```bash
lspci | grep -i ethernet
```

Displays physical Ethernet hardware if `lspci` is installed.

### Output redirection

```bash
collect > "$REPORT"
```

Everything printed by `collect` is redirected to the report file.

The script itself then prints the report location and the five section titles.

---

## `scripts/beta/LogClient.sh`

### Purpose

Configures BETA to forward all of its system logs to ALPHA.

### Initial connectivity test

```bash
timeout 3 bash -c "echo > /dev/tcp/$SERVER_IP/$LOG_PORT"
```

Bash’s `/dev/tcp/host/port` attempts a TCP connection.

If ALPHA cannot be reached on port 514, the script exits immediately with an error.

This satisfies the requirement that the client must check the server before configuring forwarding.

### Hostname

```bash
hostnamectl set-hostname beta
```

The hostname is important because ALPHA uses it to create:

```text
/var/log/remote/beta/beta.log
```

The script also updates `/etc/hosts`.

### rsyslog forwarding configuration

The configuration uses:

```text
*.* action(type="omfwd" target="ALPHA" port="514" protocol="tcp")
```

`*.*` means all facilities and all priority levels.

TCP is used so messages are more reliable than UDP.

The disk-assisted queue allows rsyslog to retain messages temporarily if ALPHA is unavailable.

### Test events

The script creates:

1. A manual `logger` message
2. A sudo event
3. Instructions for generating a failed SSH login into BETA

The failed login must be directed **into BETA**. A failed login from BETA into ALPHA would be logged by ALPHA and would not prove that BETA forwarding works.

---

## `scripts/beta/Remote.sh`

### Purpose

From BETA, this script:

1. Creates an SSH key
2. Installs the key on ALPHA
3. Tests passwordless SSH
4. Tests passwordless SFTP
5. Executes a remote command
6. Downloads ALPHA’s Apache page
7. Uploads the SysInfo report to ALPHA

It must be run as a normal user, not root.

### SSH key

```bash
ssh-keygen -t ed25519 -N "" -f "$KEY"
```

- `ed25519` is the key algorithm
- `-N ""` creates an empty passphrase
- `-f` specifies the key location

The private key remains on BETA. The public key is copied to ALPHA.

### Installing the key

```bash
ssh-copy-id -i "$KEY.pub" "$TARGET"
```

This normally asks for the ALPHA `user1` password once.

After that, the key allows passwordless access.

### Batch mode

```bash
-o BatchMode=yes
```

This ensures SSH never asks for a password. If key authentication is not working, the command fails instead.

### SSH and SFTP

SSH executes:

```bash
echo "SSH OK..."
```

SFTP is tested using:

```bash
echo "pwd" | sftp ... -b -
```

`-b -` means SFTP reads batch commands from standard input.

### Remote command

The script remotely displays:

- Hostname
- Uptime
- Disk space

The command is enclosed in quotes and executed on ALPHA.

### HTTP download

```bash
curl -fsS http://alpha/index.html -o ...
```

If `curl` fails, the script tries `wget`.

This is HTTP access, not SSH access. It verifies that Apache is serving ALPHA’s `index.html`.

### SFTP upload

The script creates a batch file:

```text
put report
ls -l report
```

The report is uploaded to `user1`’s home directory on ALPHA, then SSH verifies that it arrived.

---

# 4. C program: `c-program/part-2.c`

## Purpose

The C program creates child processes. Each child randomly performs one of six file-related tasks:

1. Create a file
2. Delete a file
3. Copy a file
4. Display file information
5. Search for a word
6. List directory contents

The parent waits for the children and then displays `logfile`.

## Header files

```c
#include <stdlib.h>
```

Provides:

- `rand`
- `srand`
- `system`
- `exit`

```c
#include <math.h>
```

Provides `ceil`.

```c
#include <stdio.h>
```

Provides:

- `snprintf`
- standard input/output functions

```c
#include <unistd.h>
```

Provides:

- `sysconf`
- `fork`
- `getpid`

```c
#include <sys/wait.h>
```

Provides `wait`.

Because `ceil` is used, compilation requires the math library:

```bash
gcc part-2.c -lm -o part-2
```

## Command-line arguments

The program expects eight arguments after the program name:

```text
argv[1] file to create
argv[2] file to delete
argv[3] source file to copy
argv[4] destination file
argv[5] file whose information is displayed
argv[6] word to search
argv[7] file to search
argv[8] directory to list
```

For example, conceptually:

```bash
./part-2 new.txt old.txt source.txt copy.txt info.txt word text.txt .
```

### Important weakness

The program does not validate `argc`. If the user supplies too few arguments, the program may access invalid or null pointers. This is a likely question during a demo.

A robust program should begin with a check such as:

```c
if (argc != 9) {
    fprintf(stderr, "Usage: ...\n");
    return 1;
}
```

## Determining the child count

```c
sysconf(_SC_NPROCESSORS_ONLN)
```

returns the number of online logical processors.

The program calculates:

```c
ceil(number_of_processors / 4.0)
```

The intention is to create approximately half the cores, with at least one child.

However, the implementation divides by **4**, not by 2. For example:

- 2 processors → 1 child
- 4 processors → 1 child
- 8 processors → 2 children

This does not exactly match the project requirement of using half the cores. It also counts logical processors rather than necessarily physical cores.

## Creating the log

```c
system("touch logfile");
```

The parent creates the log before forking.

`touch` creates the file if missing but does not clear an existing file. Therefore, repeated executions append to the old log instead of starting cleanly.

## Creating children

```c
for (int i = 0; i < sibling_count; ++i)
{
    pid = fork();

    if (!pid)
    {
        break;
    }
}
```

`fork()` duplicates the current process.

Its return value is:

- `0` in the child
- Child PID in the parent
- `-1` if fork fails

The child breaks out of the loop. The parent continues creating more children.

The result is:

- One parent
- `sibling_count` child processes

The children are siblings because they are all directly created by the same parent.

## Parent behavior

```c
if (pid)
```

The parent sees a positive child PID, so it enters this block.

```c
for (int i = 0; i < sibling_count; ++i)
{
    wait(NULL);
}
```

The parent waits for all expected children to finish.

Then:

```c
system("cat logfile");
exit(0);
```

It prints the accumulated log and exits.

### Weakness

The condition treats any non-zero value as the parent case. A failed `fork()` returns `-1`, which is also non-zero, so fork failures are not handled correctly.

## Random task assignment

Each child seeds the random generator using its PID:

```c
srand(getpid());
```

Because sibling processes have different PIDs, they usually receive different random sequences.

```c
int r = (rand() % 6) + 1;
```

This produces a value from 1 to 6.

The `switch` selects the child’s task.

## Task 1: create a file

```c
snprintf(command, sizeof(command), "touch %s", argv[1]);
```

Builds a shell command.

```c
if (!system(command))
```

`system` returns zero if the command succeeds.

On success, the child appends a timestamped message to `logfile`.

## Task 2: delete a file

```bash
rm -f
```

The `-f` option prevents an error if the file does not exist.

This means the delete operation can appear successful even if there was nothing to delete.

## Task 3: copy a file

```bash
cp source destination
```

The source is `argv[3]`; the destination is `argv[4]`.

## Task 4: display file information

```bash
ls -la file
```

This displays:

- Permissions
- Owner
- Group
- File size
- Modification time
- Filename

The output goes directly to the terminal. The success message is written to the log, but the actual `ls` output is not stored there.

## Task 5: search for a word

```bash
grep word < file
```

The first command displays matching lines.

If successful, the program logs a success message and runs `grep` again, this time appending the results to `logfile`.

A no-match result causes `grep` to return non-zero, so it is treated as unsuccessful even though the search itself completed normally.

## Task 6: list a directory

```bash
ls directory
```

The program displays the directory contents, logs success, and then runs `ls` a second time to append the results to `logfile`.

## Important C safety problems

The program is suitable for demonstrating `fork`, `wait`, command-line arguments, and process coordination, but it has several weaknesses:

1. **No argument-count validation**
   - Missing arguments can cause undefined behavior.

2. **Use of `system()`**
   - User-provided filenames are inserted into shell commands.
   - Spaces, quotes, semicolons, or shell metacharacters can break commands or execute unintended commands.

3. **No `fork()` error handling**
   - `fork()` returning `-1` is not handled.

4. **Incorrect processor division**
   - The code divides by four, while the specification says half the cores.

5. **Log is not cleared**
   - `touch logfile` preserves previous contents.

6. **Concurrent writes**
   - Multiple children append to the same file without synchronization.

7. **Fixed `wait()` count**
   - The parent assumes every `fork()` succeeded.

8. **Unused `argc`**
   - This caused the compiler warning.

9. **No child-specific error report**
   - If a command fails, the child simply exits without logging the failure.

10. **`return 0` is unreachable**
    - The program calls `exit(0)` before reaching the final `return 0`.

---

# 5. Main concepts to explain during the demo

## Why use `sudo`?

Administrative actions such as user creation, package installation, service configuration, firewall changes, and reading kernel logs require root privileges.

## Difference between `>` and `>>`

```bash
> file
```

overwrites the file.

```bash
>> file
```

appends to the file.

## Why use `systemctl enable`?

`enable` configures automatic startup at boot. It does not necessarily start the service immediately. `start` or `restart` controls the current running state.

## Why use `rsyslog`?

`rsyslog` collects and forwards system log messages. ALPHA acts as the centralized receiver, while BETA forwards its messages.

## Why use SSH keys?

A script should not type passwords automatically. Public-key authentication allows passwordless SSH and SFTP after a one-time key installation.

## Why does the parent call `wait()`?

Without `wait()`, the parent could print the log before children finish writing to it. `wait()` ensures the children complete first.

## What is the difference between a process and a thread?

This project creates processes using `fork()`. Each child has its own process identity and memory space. Threads would share the same process memory and are not used here.

## What does an exit status mean?

Commands return:

- `0` for success
- Non-zero for failure

Shell scripts and the C program use this to decide whether operations succeeded.