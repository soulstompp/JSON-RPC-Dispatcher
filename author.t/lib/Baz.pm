package Baz;

use Moose;
extends 'Bar';

sub barf {
    my $self = shift;

    die "hurp!\n";
}

__PACKAGE__->register_rpc_method_names( qw( barf ) );

1;
