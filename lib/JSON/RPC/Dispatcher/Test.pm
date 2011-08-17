package JSON::RPC::Dispatcher::Test;

use strict;

use Plack::Test;

our @ISA = qw(Plack::Test);
our @EXPORT = qw(test_psgi test_rpc_dispatch build_request build_response build_error_response build_response_json build_error_response_json build_response_hash build_error_response_hash build_response_hashref build_error_response_hashref);

use JSON;

use Test::More;
use HTTP::Request;
use HTTP::Response;

sub test_rpc_dispatch {
    my (%params) = @_;

    die "need an app object in order to dispatch an rpc test" unless defined $params{'app'}; 
    die "need a test name in order to dispatch an rpc test" unless defined $params{'test_name'}; 
    die "need a request object in order to dispatch an rpc test" unless defined $params{'request'}; 
    die "need a response object in order to dispatch an rpc test" unless defined $params{'response'}; 

    $params{'response'}->request($params{'request'});
    
    test_psgi $params{'app'}, sub {
        my $cb = shift;

        my $response = $cb->($params{'request'});

        $response->content(encode_json(decode_json($response->content())));

        is_deeply($response, $params{'response'}, $params{'test_name'});
    };

    return undef;    
}

#TODO: this is actually build_request_json
sub build_request {    
    my (%params) = @_;

    my %rpc_params = ();

    my %defaults = (
                    uri => '/',
                    http_headers => undef,
                    http_request_method => 'POST',
                    rpc_version => "2.0",
                    rpc_method => undef,
                    rpc_params => undef,
                    rpc_id => 1, 
                   );    

    for my $key (keys %defaults) {
        $params{$key} ||= $defaults{$key};
    }

    die "rpc_method required for build_request()" unless defined $params{'rpc_method'};

    @rpc_params{qw(jsonrpc method params id)} = @params{qw(rpc_version rpc_method rpc_params rpc_id)};

    my $request_content = encode_json( { map { $_ => $rpc_params{$_} } grep { defined $rpc_params{$_} } keys %rpc_params} );


    return HTTP::Request->new($params{'http_request_method'}, $params{'uri'}, $params{'http_headers'}, $request_content);
}

sub build_response {
    my %params = @_;

    my %defaults = (
                    status => 200,
                    request => undef,
                   );

    for my $key (keys %defaults) {
        $params{$key} ||= $defaults{$key};
    }

    my $content = build_response_json(map {$_ => $params{$_}} qw(jsonrpc id result)),

    my $request = $params{'request'};
    delete $params{'request'};

    my %headers = (); 

    if (defined $params{'headers'}) {
        %headers = %{$params{'headers'}};
    }

    $headers{'content-type'} ||= 'application/json-rpc';
    $headers{'content-length'} ||= length $content;

    #HTTP::Response->new($code, $msg, $header, $content)  

    my $response = HTTP::Response->new($params{'status'}, 'OK', [%headers], $content);

    if (defined $request) {
        $response->request($request);
    }

    return $response;    
}

sub build_response_json {
    my %params = @_;

    my %response_hash = build_response_hash(%params); 

    return encode_json(\%response_hash);     
}

sub build_response_hashref {
    my %params = @_;
  
    my %response_hash = build_response_hash(%params); 
     
    return \%response_hash; 
}

sub build_response_hash {
    my %response_hash = @_;

    my %defaults = (
                    jsonrpc => '2.0',
                    id => 1,
                    result => undef,
                   );

    for my $key (keys %defaults) {
        $response_hash{$key} ||= $defaults{$key};
    }

    die "cannot build rpc response without value for result (any scalar/reference should do)" unless defined $response_hash{'result'}; 

    return %response_hash;
}

sub build_error_response {
    my %params = @_;

    my %defaults = (
                    http_status => undef,
                    http_message => undef,
                    request => undef,
                   );
    
    for my $key (keys %defaults) {
        $params{$key} ||= $defaults{$key};
    }

    die "http_status required to build an error response" unless defined $params{'http_status'};
    die "http_message required to build an error response" unless defined $params{'http_message'};

    my $request = $params{'request'};
    delete $params{'request'};

    my $content = build_error_response_json(map {$_ => $params{$_}} qw(jsonrpc id error_data error_message error_code)),
    
    my %headers = (); 

    if (defined $params{'headers'}) {
        %headers = %{$params{'headers'}};
    }

    $headers{'content-type'} ||= 'application/json-rpc';
    $headers{'content-length'} ||= length $content;

    my $response = HTTP::Response->new($params{'http_status'}, $params{'http_message'}, [%headers], $content);

    if (defined $request) {
        $response->request($request);
    }

    return $response;
}

sub build_error_response_json {
    my %params = @_;

    my %response_hash = build_error_response_hash(%params); 

    return encode_json(\%response_hash);     
}

sub build_error_response_hashref {
    my %params = @_;
  
    my %response_hash = build_error_response_hash(%params); 
     
    return \%response_hash; 
}

sub build_error_response_hash {
    my %params = @_;

    my %error_params = ();

    my %defaults = (
                    jsonrpc => '2.0',
                    id => 1,
                    error_data => undef,
                    error_message => undef,
                    error_code    => undef,
                   );
    
    #{"jsonrpc":"2.0","error":{"data":"rpc_metod_names","message":"Method not found.","code":-32601},"id":1}
    for my $key (keys %defaults) {
        $params{$key} ||= $defaults{$key};
    }

    die "error_data required by build_error_response_json" unless defined $params{'error_data'};
    die "error_message required by build_error_response_json" unless defined $params{'error_message'};
    die "error_code required by build_error_response_json" unless defined $params{'error_code'} ;
    
    @error_params{qw(jsonrpc id)} = @params{qw(jsonrpc id)};

    $error_params{'error'} = {
                              data => $params{'error_data'},
                              message => $params{'error_message'},
                              code    => $params{'error_code'},
                             };   
 
    return %error_params;     
} 

no Moose;

1;
