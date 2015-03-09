# jobparallel
Perl script to run commands in parallel with a given set of arguments 
and number of threads.

Runs a command with various threads in parallel, with a given set of 
arguments (Read from a file, one set of arguments per line), running
with a given number of threads. Once done, does something to notify 
you of completion.

Usage: ./run.pl <command> <argsfile> <number_of_threads>
        where <command> includes the string __ARGS__ somewhere, which 
        will be replaced by the arguments from <argsfile>.
        
To adjust where logs will be put and what is done once a command
finishes, change settings in the source. Best used together with a
script that will deliver e-mail locally, such as the mailecho.pl
included in this repository.
