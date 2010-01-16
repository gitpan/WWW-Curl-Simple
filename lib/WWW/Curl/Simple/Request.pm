package WWW::Curl::Simple::Request;
our $VERSION = '0.100160';
# ABSTRACT: A small class representing request/response



use Moose;
use WWW::Curl::Easy;
use Carp qw/croak/;
use Scalar::Util qw/weaken/;

use namespace::clean -except => 'meta';


has 'agent' => (is => 'rw', isa => 'Str', required => 0, lazy_build => 1);

sub _build_agent {
    return "WWW::Curl::Simple/" . $WWW::Curl::Simple::VERSION;
}


has 'body' => (is => 'rw', isa => 'ScalarRef', required => 0);


has 'head' => (is => 'rw', isa => 'ScalarRef', required => 0);


has 'request' => (is => 'ro', isa => 'HTTP::Request');


has 'easy' => (is => 'rw', isa => 'WWW::Curl::Easy', required => 0, lazy_build => 1);

sub _build_easy {
    my ($self) = @_;
    
    my $req = $self->request;
    # return ourselves as a WWW::Curl::Easy-object?
    

    my $curl = new WWW::Curl::Easy;
    
    $curl->setopt(CURLOPT_NOPROGRESS,1);
    $curl->setopt(CURLOPT_USERAGENT, $self->agent);
    
    my $url = $req->uri->as_string;
    $curl->setopt(CURLOPT_URL, $url);
    if ($req->method eq 'POST') {
        $curl->setopt(CURLOPT_POST, 1);
        $curl->setopt(CURLOPT_POSTFIELDS, $req->content);
    }
    
    my @headers;
    foreach my $h (+$req->headers->header_field_names) {
        #warn "h: $h";
        push(@headers, "$h: " . $req->header($h));
    }
    if (scalar(@headers)) {
        $curl->setopt(CURLOPT_HTTPHEADER, \@headers);
    }
    my ($body_ref, $head_ref);
    $self->body(\$body_ref);
    $self->head(\$head_ref);
    open (my $fileb, ">", \$body_ref);
    $curl->setopt(CURLOPT_WRITEDATA,$fileb);
    
    my $h = $self->head;
    open (my $fileh, ">", \$head_ref);
    $curl->setopt(CURLOPT_WRITEHEADER,$fileh);
        
    return $curl;
    
}


sub perform {
    my ($self) = @_;
    
    my $retcode = $self->easy->perform;
    # Looking at the results...
    if ($retcode == 0) {
            return $self->response;
    } else {
            croak("An error happened: ".$self->easy->strerror($retcode)." ($retcode)\n");
    }
    
}


sub response {
    my ($self) = @_;
    my $res = HTTP::Response->parse(${$self->head} . "\r" . ${$self->body});
    $res->request($self->request);
    $res->content(${$self->body});
    return $res;
}

1;
__END__
=pod

=head1 NAME

WWW::Curl::Simple::Request - A small class representing request/response

=head1 VERSION

version 0.100160

=head1 DESCRIPTION

Just a way to collect things used by both single and multi, and some
WWW::Curl setup. You shouldn't need to use this class anywhere, although
C<< $curl->perform >> returns objects of this class

=head1 ATTRIBUTES

=head2 agent

A String that will be sent as the user-agent string. Defaults to

=head2 body

The body of the response

=head2 head

The head of the response

=head2 request

The HTTP::Request-object that we where created with. 

=head2 easy

our WWW::Curl::Easy-object

=head1 METHODS

=head2 perform

Performs the actuall request trough WWW::Curl::Easy. Used mostly in
single request land. Will croak on errors.

=head2 response

Returns a HTTP::Response that represents the response of this object.

Also sets request on the response object to the original request object.

=head1 AUTHOR

  Andreas Marienborg <andremar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Andreas Marienborg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

