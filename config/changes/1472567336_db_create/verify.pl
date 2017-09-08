#!/usr/bin/env perl
use exact;
use Config::App;

eval {
    use CBQZ;
    my $dq = CBQZ->new->dq;
};
print '', ( ($@) ? 0 : 1 ), "\n";
