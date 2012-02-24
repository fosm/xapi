#!/usr/bin/perl
#
# Object:    serverLink/cgi
# Component: serverLink.cgi
#
# serverLink.cgi
# Copyright 2000,2011 George James Software Limited
#

# This is what it does:
# 1 Opens a socket connection to an M server
# 2 If the request is a POST then reads STDIN and creates a
#   POST_DATA environment variable (this probably won't work for
#   very large amounts of post data, but its good for 30kbytes).
# 3 Copies all environment variables to the socket in the format:
#       %ENV:environment_variable=value
# 4 Copies the response from the socket to STDOUT
# Anything else should probably be done on the M server

# Usage:
#  serverLink.cgi
# Expects:
#  $ENV{'SERVER_LINK_IP'} = IP address of M server
#  $ENV{'SERVER_LINK_PORT'} = Port number on which M server is listening
#  $ENV{'SERVER_LINK_PASSPHRASE'} = ServerLink's passphrase

use strict;
use IO::Socket;
open STDERR, '>>/tmp/error.log';

my ($socket, $line, $key, $postData, $payload, $peerPort, $peerAddr, $serverLinkAuth, $i);

$peerAddr = $ENV{'SERVER_LINK_IP'};
$peerPort = $ENV{'SERVER_LINK_PORT'};
$serverLinkAuth = $ENV{'SERVER_LINK_PASSPHRASE'};


# Create socket object with connection to M server
# If no connection then return an Internal Server Error header.  For security
# reasons do not send any other kind of identifying info.  The web-server will
# log the response which is where you should look for debugging and problem diagnosis.
for ($i=0;$i<=30;$i++) {
  if ($socket = IO::Socket::INET->new(Proto    => "tcp",
        			      PeerAddr => "$peerAddr",
				      Timeout => 1000000,
				      PeerPort => "$peerPort")) { 
	print $socket "serverLink.cgi/1.4\n";
	if ($line=<$socket>) {
		if ($line=="r.serverLink/1.4") { last; } }
	}
  elsif ($i==30) {
		print STDOUT "Status: 503 Service Unavailable\015\012";
		print STDOUT "Content-Type: text/html\015\012";
		print STDOUT "\015\012";
		exit;}

  else { 
	if ($i>3) {sleep 1;}
  } 
}


# Stuff the pass-phrase into the ENV hash so that it gets passed to the M server
$ENV{'GJS_SERVERLINK_AUTH'}=$serverLinkAuth;


# Get POST form contents from STDIN and append to the QUERY_STRING
# environment variable.  To the user the Query String will always
# be in the environment variable (nice and simple...too simple).
if ($ENV{'REQUEST_METHOD'} eq 'POST') {
	read(STDIN,$postData,$ENV{'CONTENT_LENGTH'});
	$ENV{'POST_DATA'}=$postData;
}
if ($ENV{'REQUEST_METHOD'} eq 'PUT') {
        read(STDIN,$payload,$ENV{'CONTENT_LENGTH'});
        $ENV{'PAYLOAD'}=$payload;
}

# Walk ENV hash and print
foreach $key (keys %ENV) {
	print $socket "%ENV:$key=$ENV{$key}\n"};


# Send %END to indicate end of message
print $socket "%END\n";


# Disable buffering for STDOUT
select((select(STDOUT), $|=1)[0]);
# Now read the response from the socket and echo it back to the web-server
# which will be waiting on STDOUT.
while ($line = <$socket>) {
	print STDOUT $line or die "Client gone\n";
}

# Done
die "Done\n";
