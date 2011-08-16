package JSON::RPC::Dispatcher::Test;

use strict;

use Plack::Test;

our @ISA = qw(Plack::Test);
our @EXPORT = qw(test_psgi build_request build_response_json build_error_response_json build_response_hash build_error_response_hash build_response_hashref build_error_response_hashref);

use JSON;

use HTTP::Request;

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
