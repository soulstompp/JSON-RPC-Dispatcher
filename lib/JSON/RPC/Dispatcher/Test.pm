package JSON::RPC::Dispatcher::Test;

use Plack::Test;

our @ISA = qw(Plack::Test);
our @EXPORT = qw(test_psgi build_request build_response_json);

use JSON;

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

    for my $param_key (keys %defaults) {
        $params{$param_key} ||= $defaults{$param_key};
    }

    die "rpc_method required for build_request()" unless defined $params{'rpc_method'};

    @rpc_params{qw(jsonrpc method params id)} = @params{qw(rpc_version rpc_method rpc_params rpc_id)};

    my $request_content = encode_json( { map { $_ => $rpc_params{$_} } grep { defined $rpc_params{$_} } keys %rpc_params} );

    warn "request content: $request_content";

    return HTTP::Request->new($params{'http_request_method'}, $params{'uri'}, $params{'http_headers'}, $request_content);
}

sub build_response_json {
    my %params = @_;

    my %defaults = (
                    jsonrpc => '2.0',
                    id => 1,
                    result => undef,
                   );

    for my $param_key (keys %defaults) {
        $params{$param_key} ||= $defaults{$param_key};
    }

    die "cannot build rpc response without value for result (any scalar/reference should do)" unless defined $params{'result'}; 

    return encode_json(\%params);     
} 

no Moose;

1;
