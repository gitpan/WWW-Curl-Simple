package TestServer;
our $VERSION = '0.100180';

use strict;
use base qw(Net::Server::Single);

sub process_request {
    my $self = shift;

    print "HTTP/1.0 200 OK\n";
    print "\n";
    print "OK";
    exit(0);
}
1;
