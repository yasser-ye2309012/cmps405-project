#include <stdlib.h>
#include <math.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/wait.h>

/*

Command line arguments:

1: file to create
2: file to delete
3: file to copy (source)
4: destination
5: file to display information
6: word to search
7: file to search
8: directory to list contents

*/

int main(int argc, char const *argv[])
{
    // divide by 4 since the number of threads is returned, not core count (usually 2 threads per core)
    int sibling_count = (int)ceil((double)sysconf(_SC_NPROCESSORS_ONLN) / 4.0);
    pid_t pid;

    system("touch logfile");

    for (int i = 0; i < sibling_count; ++i)
    {
        // create child and exit loop
        pid = fork();
        if (!pid)
        {
            break;
        }
    }

    // parent waits for all children before outputting logfile
    if (pid)
    {
        for (int i = 0; i < sibling_count; ++i)
        {
            wait(NULL);
        }
        system("cat logfile");
        exit(0);
    }

    // randomise a seed from the child's pid which is unique for each child
    srand(getpid());

    char command[1024];
    int r = (rand() % 6) + 1;

    switch (r)
    {
    case 1: // create file
        snprintf(command, sizeof(command), "touch %s", argv[1]);
        if (!system(command))
        {
            system("echo \"$(date): child successfully created file\" | cat >> logfile");
        }
        break;
    case 2: // delete file
        snprintf(command, sizeof(command), "rm -f %s", argv[2]);
        if (!system(command))
        {
            system("echo \"$(date): child successfully deleted file\" | cat >> logfile");
        }
        break;
    case 3: // copy file
        snprintf(command, sizeof(command), "cp %s %s", argv[3], argv[4]);
        if (!system(command))
        {
            system("echo \"$(date): child successfully copied file\" | cat >> logfile");
        }
        break;
    case 4: // display file info
        snprintf(command, sizeof(command), "ls -la %s", argv[5]);
        if (!system(command))
        {
            system("echo \"$(date): child successfully displayed file information\" | cat >> logfile");
        }
        break;
    case 5: // search for word in file and save results
        snprintf(command, sizeof(command), "grep %s < %s", argv[6], argv[7]);
        if (!system(command))
        {
            system("echo \"$(date): child successfully searched for word in file, results:\" | cat >> logfile");
            snprintf(command, sizeof(command), "grep %s < %s >> logfile", argv[6], argv[7]);
            system(command);
        }
        break;
    case 6: // list directory contents and save results
        snprintf(command, sizeof(command), "ls %s", argv[8]);
        if (!system(command))
        {
            system("echo \"$(date): child successfully listed directory contents, results:\" | cat >> logfile");
            snprintf(command, sizeof(command), "ls %s >> logfile", argv[8]);
            system(command);
        }
        break;
    }
    exit(0);

    return 0;
}