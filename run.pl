#!/usr/bin/perl

##
# Runs a command with various threads in parallel, with a given set of 
# arguments (Read from a file, one set of arguments per line), running
# with a given number of threads. Once done, does something to notify 
# you of completion.
# 
# Usage: ./run.pl <command> <argsfile> <number_of_threads>
#        where <command> includes the string __ARGS__ somewhere, which 
#        will be replaced by the arguments from <argsfile>.
##

# Setup:
my $LOG_DIR = "~/thread_logs/";
my $COMPLETION_COMMAND = "wget -O - 'http://example.com/mailecho.pl?title=Status - __THREAD_COUNTER__&message=Command __COMMAND__ succeeded, logs are __ERRLOG__ / __OUTLOG__'";
my $ERROR_COMMAND = "wget -O - 'http://example.com/mailecho.pl?title=ALERT - ERROR - __THREAD_COUNTER__&message=Command __COMMAND__ failed, logs are __ERRLOG__ / __OUTLOG__'";

my $command = $ARGV[0];
my $argsfile = $ARGV[1];
my $cores = $ARGV[2];

use threads;
use threads::shared;
use Data::Dumper;

my $counter :shared;
$counter = -1;

# Read argsfile
open my $argsfileh, '<', $argsfile;
chomp(my @argsarr = <$argsfileh>);
close $argsfileh;
my $max = scalar @argsarr;

# Single worker thread fnction
sub worker() {
    while(1) {
        my $tid = threads->tid();
        my $local_counter;
        {
            lock($counter);
            if($counter >= $max) {
                threads->exit(0);
            }
            $counter++;
            if($counter >= $max) {
                threads->exit(0);
            }
            $local_counter = $counter;
        }
        my $local_args = $argsarr[$local_counter];    
        my $local_command = $command;        
        my $time = time();
        $local_command =~ s/__ARGS__/$local_args/;
        my $errlog =  $LOG_DIR . "/thread_stderr_" . $tid . "_$time.log";
        my $outlog =  $LOG_DIR . "/thread_stdout_" . $tid . "_$time.log";
        my $small_command = $local_command;
        system("echo 'Command: $local_command' > $errlog");
        system("echo 'Command: $local_command' > $outlog");
        $local_command .= " 2>> $errlog";
        $local_command .= " 1>> $outlog";
        print "Thread $tid running command: $local_command\n";
        my $status = system($local_command);
        if($status == 0) {
            my $command = $COMPLETION_COMMAND;
            $command =~ s/__THREAD_COUNTER__/$local_counter/g;
            $command =~ s/__COMMAND__/$small_command/g;
            $command =~ s/__ERRLOG__/$errlog/g;
            $command =~ s/__OUTLOG__/$outlog/g;
            `$command`;
            print "Thread $tid (command $small_command) succeeded\n";
            print "Thread $tid success errlog: $errlog\n";
            print "Thread $tid success errlog: $outlog\n";
        }
        else {
            my $command = $ERROR_COMMAND;
            $command =~ s/__THREAD_COUNTER__/$local_counter/g;
            $command =~ s/__COMMAND__/$small_command/g;
            $command =~ s/__ERRLOG__/$errlog/g;
            $command =~ s/__OUTLOG__/$outlog/g;            `$command`;
            print "Thread $tid (command $small_command) FAILED\n";
            print "Thread $tid FAILURE errlog: $errlog\n";
            print "Thread $tid FAILURE errlog: $outlog\n";
        }
        threads->yield();
    }
}

print "Running with $cores threads.\n";
print "Argument set: " . Dumper(@argsarr) . "\n";

my @threads;
foreach(1..$cores) {
    $threads[$_] = threads->create('worker');
}
foreach(1..$cores) {
    $threads[$_]->join();
}

print "Done\n";