use LWP::UserAgent;
use Test::More tests=>1;

my $ua = LWP::UserAgent->new;

#unless ($ua->post('http://localhost:5000/', Content=>'{"jsonrpc":"2.0","method":"ping","id":"1"}')->is_success) {
#    die "You need to 'plackup -E prod eg/app.psgi' before running these tests!";
#}

is($ua->post('http://localhost:5000/', Content=>'{"jsonrpc":"2.0","method":"sum","params":[2,3,5],"id":"1"}')->content,
    '{"jsonrpc":"2.0","id":"1","result":10}',
    'sum test - using an inherited method');



