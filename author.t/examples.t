#!/usr/bin/perl -w

use strict;

use lib qw(./lib ../lib);

use LWP::UserAgent;

use Test::More tests => 9;

use JSON;
use JSON::RPC::Dispatcher::Test;

use Plack::Util;

my $ua = LWP::UserAgent->new;

my $app = Plack::Util::load_psgi("../eg/app.psgi"); 

test_rpc_dispatch(app => $app, request => build_request(rpc_method => 'ping'), response => build_response(result => "pong"), test_name => 'ping test');

test_rpc_dispatch(app => $app, request => build_request(rpc_method => 'echo', rpc_params => ["Hello World!"]), response => build_response(result => "Hello World!"), test_name => 'echo test');

test_rpc_dispatch(app => $app, request => build_request(rpc_method => 'echo', rpc_params => ["déjà vu"]), response => build_response(result => "déjà vu"), test_name => 'utf8 test');

test_rpc_dispatch(app => $app, request => build_request(rpc_method => 'sum', rpc_params => [2,3,5]), response => build_response(result => 10), test_name => 'sum test');

test_rpc_dispatch(app => $app, request => build_request(rpc_method => 'guess', rpc_params => [5]), response => build_error_response(error_data => 5, error_message => 'Too low.', error_code => 987, http_status => 200, http_message => 'OK'), test_name => 'guess low test');

test_rpc_dispatch(app => $app, request => build_request(rpc_method => 'guess', rpc_params => [15]), response => build_error_response(error_data => 15, error_message => 'Too high.', error_code => 986, http_status => 200, http_message => 'OK'), test_name => 'guess high test');

test_rpc_dispatch(app => $app, request => build_request(rpc_method => 'guess', rpc_params => [10]), response => build_response(result => 'Correct!'), test_name => 'guess correct');

#TODO: did this one ever work?
is($ua->post('http://localhost:5000/', Content=>'{"jsonrpc":"2.0","method":"ping"}')->code, 204, 'notification test');

#TODO: we need a bulk helper module
is($ua->post('http://localhost:5000/', Content=>'[{"jsonrpc":"2.0","method":"ping"},{"jsonrpc":"2.0","method":"guess","params":[10],"id":"1"},{"jsonrpc":"2.0","method":"guess","params":[5],"id":"1"}]')->content, '[{"jsonrpc":"2.0","id":"1","result":"Correct!"},{"jsonrpc":"2.0","error":{"data":5,"message":"Too low.","code":987},"id":"1"}]', 'bulk test');


