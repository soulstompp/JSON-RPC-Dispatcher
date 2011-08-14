#!/usr/bin/perl -w

use lib qw(./lib ../lib);

use Test::More tests => 1;

use JSON::RPC::Dispatcher::Test;

use Bar;

# normal responses
my $app = Bar->new();

test_psgi $app->to_app(), sub {
    my $cb = shift;

    my $request = build_request(rpc_method => 'rpc_method_names', rpc_params => {exclusions => [qw(concat_with_spaces options)]});

    my $response = $cb->($request);
    
    is($response->content(), build_response_json(result => [qw(rpc_method_names sum utf8_string)]) , 'get back what i wanted');
};

#responses that don't propogate
