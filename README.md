# CMPS405 Project: Shell Scripting, System Administration & System Programming (Fall 2026)

Private group repository. Do not make this repository public (copying/plagiarism is penalised at -100%).

## Team

| Member | Name | Student ID | GitHub | Owns (step numbers) |
|---|---|---|---|---|
| 1 | Yasser ElMokadem | 202309012 | yasser-ye2309012 | [01] repo, [02] VMs and network, [03] `Users.sh`, [04] `Install.sh`, [05] `Connectivity.sh` |
| 2 | Mohammed Alhusali | 202212621 | mohammed-ma2212621 | [07] `SysInfo.sh`, [10] `Search.sh`, [11] `Network.sh`, [16] QA, [17] Word report, [18] submission |
| 3 | Khaled Elrefaey | 202309917 | horder6947 | [12]-[13] `FileSystem.sh`, [14]-[15] C program |
| 4 | Huthaifa Rajha | 202308103 | Hraj7a | [06] `LogServer.sh`, [08] `LogClient.sh`, [09] `Remote.sh` |

All members: [19] demo rehearsal. Section number: ______

## Environment

| VM | Hostname | Role | IP |
|---|---|---|---|
| VM1 | `alpha` | Server: users, SSH, MySQL, FTP, Apache, log server | 192.169.153.10 |
| VM2 | `beta` | Client: connectivity, remote access, reporting, log forwarding | 192.169.153.11 |

Both are Ubuntu 26.04 LTS Desktop. Real IPs and credentials go in `config.txt` (local only, git-ignored). Copy `config.example.txt` to `config.txt` and fill it in.

## Repository layout

```
.
├── README.md
├── config.example.txt      # template; real config.txt is NOT committed
├── scripts/
│   ├── alpha/              # Users.sh Install.sh Search.sh Network.sh FileSystem.sh LogServer.sh
│   └── beta/               # Connectivity.sh Remote.sh SysInfo.sh LogClient.sh
├── c-program/              # Part 2 source (.c) and any test inputs
├── logs/                   # sample outputs: Installation.log, network.log, bigfile, ...
├── screenshots/
│   ├── alpha/
│   ├── beta/
│   └── c-program/
└── report/                 # final Word report (only Member 2 edits it)
```

## Build order

Each GitHub issue title starts with its step tag `[NN]`. The `#` number is only GitHub's ID; the `[NN]` tag is the order to work in.

| Step | Task | Owner | Waits for |
|---|---|---|---|
| 01 | Repo, board, invites | M1 | |
| 02 | VMs, network, hostnames | M1 | |
| 03 | `scripts/alpha/Users.sh` | M1 | 02 |
| 04 | `scripts/alpha/Install.sh` | M1 | 02 |
| 05 | `scripts/beta/Connectivity.sh` | M1 | 02 |
| 06 | `scripts/alpha/LogServer.sh` | M4 | 02 |
| 07 | `scripts/beta/SysInfo.sh` | M2 | 02 |
| 08 | `scripts/beta/LogClient.sh` | M4 | 06 |
| 09 | `scripts/beta/Remote.sh` | M4 | 03, 04, 07 |
| 10 | `scripts/alpha/Search.sh` | M2 | 02 |
| 11 | `scripts/alpha/Network.sh` | M2 | 02 |
| 12 | `FileSystem.sh` function 1 | M3 | 02 |
| 13 | `FileSystem.sh` functions 2 and 3 | M3 | 12 |
| 14 | C program: cores, fork, arguments | M3 | 02 |
| 15 | C program: six tasks and logging | M3 | 14 |
| 16 | QA pass | M2 | 03-15 |
| 17 | Word report | M2 | 16 (skeleton can start early) |
| 18 | Zip and submit | M2 | 17 |
| 19 | Demo rehearsal | all | 16 |

Scripts can be drafted before the VMs exist; only testing waits for step 02.

## Workflow

1. Take an issue and move it to **In progress** on the project board.
2. Branch from `main`: `git checkout -b m2/search-sh`
3. Write the script with a header comment and inline comments on every logical block.
4. Run it twice on the VM. The second run must also finish with no errors.
5. Take screenshots (naming below) and add them under `screenshots/`. Copy sample output files into `logs/`.
6. Commit with a clear message: `Search.sh: add mail notification when bigfile is non-empty`
7. Open a pull request that says `Closes #<issue>`. The **reviewer** must read the script and be able to explain it.
8. Merge, then post the handoff comment on the issue if someone is waiting on you.

### Reviewers

| Author | Reviewer |
|---|---|
| Member 1 | Member 3 |
| Member 2 | Member 4 |
| Member 3 | Member 2 |
| Member 4 | Member 1 |

### Handoff comment template

```
HANDOFF -> Member X
Done: what works and how to run it
You need: IPs, usernames, file paths, commands
Watch out for: known issues or order requirements
```

### Screenshot naming

`<VM>_<Script>_Task<N>_<what>.png`, for example `ALPHA_Users.sh_Task1_run2.png`.
Every screenshot is a full-window capture, the terminal prompt with the hostname is visible, and it is taken inside the VM (not a phone photo).

### Definition of done (per script)

- [ ] File name exactly matches the spec
- [ ] Header comment plus inline comments on every logical block
- [ ] Runs twice with no errors
- [ ] Output files created (`Installation.log`, `network.log`, `bigfile`, ...) and a sample copied to `logs/`
- [ ] Screenshots committed with correct names
- [ ] PR reviewed and merged, handoff comment posted if needed

## Running scripts on the VMs

Clone the repo inside the VM (HTTPS with a personal access token) or copy scripts from the host with `scp`, then:

```bash
chmod +x scripts/alpha/*.sh scripts/beta/*.sh
sudo ./scripts/alpha/Users.sh
```

Scripts must use LF line endings (enforced by `.gitattributes`), otherwise they fail on Linux with `bad interpreter` errors.

## Rules to remember

- Scripts must be error free (-25% otherwise); run them twice.
- No source code pasted into the Word report; screenshots only, each captioned with VM, script and task.
- Submission zip: `Name1_Name2_Name3_Name4.zip` on Blackboard. Confirm the real deadline with the instructor (the spec states both 14 Oct and 31 Oct).
- Demo: tasks are picked at random and every member must explain every line.
