#!/usr/bin/perl

##
# Simple local mail echo script.
##

print "Content-type: text/html\n\n";

use CGI qw(:standard);

$to='halcy@example.com';
$from= 'status@example.com';
$subject='Work - ' . param('title');
 
open(MAIL, "|/usr/sbin/sendmail -t");
print MAIL "To: $to\n";
print MAIL "From: $from\n";
print MAIL "Subject: $subject\n\n";
print MAIL param('message') . "\n";
close(MAIL);
 
print "<html><head><title>Mail</title></head>\n<body>\n\n";
print "<h1>$title</h1><p>A message has been sent from to $to</p></body></html>";
