#!/usr/bin/perl -w

use strict;

use lib qw(./lib ../lib);

use Test::More tests => 1;

use JSON;
use JSON::RPC::Dispatcher::Test;

use Baz;

# normal responses
my $app = Baz->new();

my $good_request = build_request(rpc_method => 'rpc_method_names', rpc_params => {exclusions => [qw(concat_with_spaces options)]}); 
my $bad_method_request = build_request(rpc_method => 'rpc_metod_names', rpc_params => {exclusions => [qw(concat_with_spaces options)]}); 
my $deadly_request = build_request(rpc_method => 'barf'); 

#TODO: non-propogated tests
#TODO: proper labeling of the current tests
test_psgi $app->to_app(), sub {
    my $cb = shift;

    my $response = $cb->($good_request);
    
    is_deeply(decode_json($response->content()), build_response_hashref(result => [qw(barf rpc_method_names sum utf8_string)]) , 'propogated responses - returns method names');
    is($response->code(), 200, 'propogated responses - good request returns 200 + response object');

    $response = $cb->($bad_method_request);
    
    #{"jsonrpc":"2.0","error":{"data":"rpc_metod_names","message":"Method not found.","code":-32601},"id":1}
    is_deeply(decode_json($response->content()), build_error_response_hashref(error_data => 'rpc_metod_names', error_message => 'Method not found.', error_code => -32601));

    is($response->code(), 404, 'propogated responses - bad method request returns 404 + error response object');

    $response = $cb->($deadly_request);
   
    #{"jsonrpc":"2.0","error":{"data":"hurp!\n","message":"Internal error.","code":-32603},"id":1}
    #TODO: shouldn't we maybe cut the newlines from die/croak/whatever messages?
    is_deeply(decode_json($response->content()), build_error_response_hashref(error_data => "hurp!\n", error_message => 'Internal error.', error_code => -32603));

    is($response->code(), 500, 'propogated responses - deadly request returns 500 + error response object');
};

#responses that don't propogate
