#!/usr/bin/perl -w

use strict;

use lib qw(./lib ../lib);

use Test::More tests => 9;

use JSON;
use JSON::RPC::Dispatcher::Test;

use Baz;

my $good_request = build_request(rpc_method => 'rpc_method_names', rpc_params => {exclusions => [qw(concat_with_spaces options)]}); 
my $bad_method_request = build_request(rpc_method => 'rpc_metod_names', rpc_params => {exclusions => [qw(concat_with_spaces options)]}); 
my $deadly_request = build_request(rpc_method => 'barf'); 

# normal responses
my $code_propagating_app = Baz->new();

is($code_propagating_app->propagate_status_codes(), 1, 'propagation of status codes is on');

test_rpc_dispatch(app => $code_propagating_app->to_app(), request => $good_request, response => build_response(result => [qw(barf rpc_method_names sum utf8_string)]), test_name => 'propagated codes - returns method names');

#TODO: can't we just lookup the http status?
test_rpc_dispatch(app => $code_propagating_app->to_app(), request => $bad_method_request, response => build_error_response(error_data => 'rpc_metod_names', error_message => 'Method not found.', error_code => -32601, http_status => 404, http_message => 'Not Found'), test_name => 'propagated codes - bad method request error response');

test_rpc_dispatch(app => $code_propagating_app->to_app(), request => $bad_method_request, response => build_error_response(error_data => 'rpc_metod_names', error_message => 'Method not found.', error_code => -32601, http_status => 404, http_message => 'Not Found'), test_name => 'propagated codes - bad method request error response');

test_rpc_dispatch(app => $code_propagating_app->to_app(), request => $deadly_request, response => build_error_response(error_data => "hurp!\n", error_message => 'Internal error.', error_code => -32603, http_status => 500, http_message => 'Internal Server Error'), test_name => 'propagated codes - bad method request error response');  
  
#responses that don't propagate
my $non_code_propagating_app = Baz->new(propagate_status_codes => 0);

is($non_code_propagating_app->propagate_status_codes(), 0, 'propagation of status codes is off');
    
test_rpc_dispatch(app => $non_code_propagating_app->to_app(), request => $bad_method_request, response => build_error_response(error_data => 'rpc_metod_names', error_message => 'Method not found.', error_code => -32601, http_status => 200, http_message => 'OK'), test_name => 'propagated codes - bad method request error response');

test_rpc_dispatch(app => $non_code_propagating_app->to_app(), request => $bad_method_request, response => build_error_response(error_data => 'rpc_metod_names', error_message => 'Method not found.', error_code => -32601, http_status => 200, http_message => 'OK'), test_name => 'propagated codes - bad method request error response');

test_rpc_dispatch(app => $non_code_propagating_app->to_app(), request => $deadly_request, response => build_error_response(error_data => "hurp!\n", error_message => 'Internal error.', error_code => -32603, http_status => 200, http_message => 'OK'), test_name => 'propagated codes - bad method request error response');  
