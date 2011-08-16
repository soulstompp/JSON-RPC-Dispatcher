#!/usr/bin/perl -w

use strict;

use lib qw(./lib ../lib);

use Test::More tests => 1;

use JSON;
use JSON::RPC::Dispatcher::Test;

use Baz;

my $good_request = build_request(rpc_method => 'rpc_method_names', rpc_params => {exclusions => [qw(concat_with_spaces options)]}); 
my $bad_method_request = build_request(rpc_method => 'rpc_metod_names', rpc_params => {exclusions => [qw(concat_with_spaces options)]}); 
my $deadly_request = build_request(rpc_method => 'barf'); 

# normal responses
my $code_propagating_app = Baz->new();

is($code_propagating_app->propagate_status_codes(), 1, 'propagation of status codes is on');

test_psgi $code_propagating_app->to_app(), sub {
    my $cb = shift;

    my $response = $cb->($good_request);

    is_deeply(decode_json($response->content()), build_response_hashref(result => [qw(barf rpc_method_names sum utf8_string)]) , 'propagated codes - returns method names');
    is($response->code(), 200, 'propagated codes - good request returns 200 + response object');

    $response = $cb->($bad_method_request);
    
    #{"jsonrpc":"2.0","error":{"data":"rpc_metod_names","message":"Method not found.","code":-32601},"id":1}
    is_deeply(decode_json($response->content()), build_error_response_hashref(error_data => 'rpc_metod_names', error_message => 'Method not found.', error_code => -32601), 'propagated codes - bad method request error response');

    is($response->code(), 404, 'propagated codes - bad method request returns 404 + error response object');

    $response = $cb->($deadly_request);
   
    #{"jsonrpc":"2.0","error":{"data":"hurp!\n","message":"Internal error.","code":-32603},"id":1}
    is_deeply(decode_json($response->content()), build_error_response_hashref(error_data => "hurp!\n", error_message => 'Internal error.', error_code => -32603), 'propagated codes - deadly request error response');

    is($response->code(), 500, 'propagated codes - deadly request returns 500 + error response object');
};

#responses that don't propagate
my $non_code_propagating_app = Baz->new(propagate_status_codes => 0);

is($non_code_propagating_app->propagate_status_codes(), 0, 'propagation of status codes is off');
    
test_psgi $non_code_propagating_app->to_app(), sub {
    my $cb = shift;

    my $response = $cb->($good_request);
    
    is_deeply(decode_json($response->content()), build_response_hashref(result => [qw(barf rpc_method_names sum utf8_string)]) , 'propagated codes - returns method names');
    is($response->code(), 200, 'non-propagated codes - good request returns 200 + response object');

    $response = $cb->($bad_method_request);
    
    #{"jsonrpc":"2.0","error":{"data":"rpc_metod_names","message":"Method not found.","code":-32601},"id":1}
    is_deeply(decode_json($response->content()), build_error_response_hashref(error_data => 'rpc_metod_names', error_message => 'Method not found.', error_code => -32601), 'non-propagated codes - bad method request error response');

    is($response->code(), 200, 'non-propagated codes - bad method request returns 200 + error response object');

    $response = $cb->($deadly_request);
   
    #{"jsonrpc":"2.0","error":{"data":"hurp!\n","message":"Internal error.","code":-32603},"id":1}
    is_deeply(decode_json($response->content()), build_error_response_hashref(error_data => "hurp!\n", error_message => 'Internal error.', error_code => -32603), 'non-propagated codes - bad method request error response');

    is($response->code(), 200, 'non-propagated codes - deadly request returns 200 + error response object');
};
