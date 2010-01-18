package WWW::Curl::Simple;
our $VERSION = '0.100181';
# ABSTRACT: A Simpler interface to WWW::Curl
use Moose;

use HTTP::Request;
use HTTP::Response;
use Carp qw/croak carp/;
use WWW::Curl::Simple::Request;
use WWW::Curl::Multi;
use WWW::Curl::Easy;

#use base 'LWP::Parallel::UserAgent';

use namespace::clean -except => 'meta';





sub request {
    my ($self, $req) = @_;
    
    my $curl = WWW::Curl::Simple::Request->new(request => $req);
    
    # Starts the actual request
    return $curl->perform;
}



sub get {
    my ($self, $uri) = @_;
    return $self->request(HTTP::Request->new(GET => $uri));
}


sub post {
    my ($self, $uri, $form) = @_;
    
    return $self->request(HTTP::Request->new(POST => $uri, undef, $form));
}



has _requests => (
    traits => ['Array'], 
    is => 'ro', 
    isa => 'ArrayRef[WWW::Curl::Simple::Request]', 
    handles => {
        _add_request => 'push',
        requests => 'elements',
        _find_request => 'first',
        _count_requests => 'count',
        _get_request => 'get',
        _delete_request => 'delete',
    },
    default => sub { [] },
);

sub add_request {
    my ($self, $req) = @_;
    $req = WWW::Curl::Simple::Request->new(request => $req);
    $self->_add_request($req);
    
    return $req;
}


__PACKAGE__->meta->add_package_symbol('&register',
    __PACKAGE__->meta->get_package_symbol('&add_request')
);


sub has_request {
    my ($self, $req) = @_;
    
    $self->_find_request(sub {
        $_ == $req
    });
}


sub delete_request {
    my ($self, $req) = @_;
    
    return unless $self->has_request($req);
    # need to find the index
    my $c = $self->_count_requests;
    
    while ($c--) {
        $self->_delete_request($c) if ($self->_get_request($c) == $req);
    }
    return 1;
}



sub perform {
    my ($self) = @_;
    
    my $curlm = WWW::Curl::Multi->new;
    
    my %reqs;
    my $i = 0;
    foreach my $req ($self->requests) {
        $i++;
        my $curl = $req->easy;
        # we set this so we have the ref later on
        $curl->setopt(CURLOPT_PRIVATE, $i);
        
        # here we also mangle all requests based on options
        # XXX: Should re-factor this to be a metaclass/trait on the attributes,
        # and a general method that takes all those and applies the propper setopt
        # calls
        if ($self->timeout_ms) {
            unless ($WWW::Curl::Easy::CURLOPT_TIMEOUT_MS) {
                croak( "Your trying to use timeout_ms, but your libcurl is apperantly older than 7.16.12.");
            }
            $curl->setopt($WWW::Curl::Easy::CURLOPT_TIMEOUT_MS, $self->timeout_ms) if $self->timeout_ms;
            $curl->setopt($WWW::Curl::Easy::CURLOPT_CONNECTTIMEOUT_MS, $self->connection_timeout_ms) if $self->connection_timeout_ms;                
        } else {
            $curl->setopt(CURLOPT_TIMEOUT, $self->timeout) if $self->timeout;
            $curl->setopt(CURLOPT_CONNECTTIMEOUT, $self->connection_timeout) if $self->connection_timeout;
        }
        
        $curlm->add_handle($curl);
        
        $reqs{$i} = $req;
    }
    my @res;
    while ($i) {
        my $active_transfers = $curlm->perform;
        if ($active_transfers != $i) {
            while (my ($id,$retcode) = $curlm->info_read) {
                if ($id) {
                    $i--;
                    my $req = $reqs{$id};
                    unless ($retcode == 0) {
                        my $err = "Error during handeling of request: " 
                            .$req->easy->strerror($retcode)." ". $req->request->uri;
                        
                        croak($err) if $self->fatal;
                        carp($err) unless $self->fatal;
                    }
                    push(@res, $req);
                    delete($reqs{$id});
                }
            }
        }
    }
    return @res;
}



sub wait {
    my $self = shift;
    
    my @res = $self->perform(@_);
    
    # convert to a hash
    my %res;
    
    while (my $r = pop @res) {
        #warn "adding $r at " . scalar(@res);
        $res{scalar(@res)} = $r;
    }
    
    return \%res;
}




has 'timeout' => (is => 'ro', isa => 'Int');
has 'timeout_ms' => (is => 'ro', isa => 'Int');


has 'connection_timeout' => (is => 'ro', isa => 'Int');
has 'connection_timeout_ms' => (is => 'ro', isa => 'Int');



has 'fatal' => (is => 'ro', isa => 'Bool', default => 1);

1; # End of WWW::Curl::Simple

__END__
=pod

=head1 NAME

WWW::Curl::Simple - A Simpler interface to WWW::Curl

=head1 VERSION

version 0.100181

=head1 SYNOPSIS

It makes it easier to use WWW::Curl::(Easy|Multi), or so I hope

    use WWW::Curl::Simple;

    my $curl = WWW::Curl::Simple->new();
    
    my $res = $curl->get('http://www.google.com/');

=head1 ATTRIBUTES

=head2 timeout / timeout_ms

Sets the timeout of individual requests, in seconds or milliseconds

=head2 connection_timeout /connection_timeout_ms

Sets the timeout of the connect phase of requests, in seconds or milliseconds

=head2 fatal

Defaults to true, but if set to false, it will make failure in multi-requests
warn instead of die.

=head1 METHODS

=head2 request($req)

$req should be a  HTTP::Request object.

If you have a URI-string or object, look at the get-method instead.
Returns a L<HTTP::Response> object.

=head2 get($uri || URI)

Accepts one parameter, which should be a reference to a URI object or a
string representing a uri. Returns a L<HTTP::Response> object.

=head2 post($uri || URI, $form)

Created a HTTP::Request of type POST to $uri, which can be a string
or a URI object, and sets the form of the request to $form. See
L<HTTP::Request> for more information on the format of $form

=head2 add_request($req)

Adds $req (HTTP::Request) to the list of URL's to fetch. Returns a 
L<WWW::Simple::Curl::Request>

=head2 register($req)

This is just an alias for add_request

=head2 has_request $request

Will return true if $request is one of our requests

=head2 delete_request $req

Will remove $req from our list of requests

=head2 perform

Does all the requests added with add_request, and returns a 
list of HTTP::Response-objects

=head2 wait

These methods are here to provide an easier transition from
L<LWP::Parallel::UserAgent>. It is by no means a drop in replacement,
but using C<wait> instead of C<perform> makes the return-value perform
more alike

=head1 LWP::Parallel::UserAgent compliant methods

=head1 AUTHOR

  Andreas Marienborg <andremar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Andreas Marienborg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

