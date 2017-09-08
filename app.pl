#!/usr/bin/env perl
use exact;
use Config::App;
use Mojolicious::Commands;

Mojolicious::Commands->start_app('CBQZ::Control');

__END__
=pod

=head1 NAME

app.pl - CBQZ Application

=head1 SYNOPSIS

    morbo -v app.pl
    morbo -v -w app.pl -w config/app.yaml -w runtime/config.yaml -w lib -w templates app.pl

    hypnotoad app.pl
    hypnotoad -f app.pl # run in the foreground

=head1 DESCRIPTION

This is the CBQZ application. For development, you will likely want to run
the application under "morbo".

    morbo -v -w app.pl -w config/app.yaml -w runtime/config.yaml -w lib -w templates app.pl

Supply a "-w" parameter for each file or directory you want to add to the
"watch list". If any files changes within the watch list, it triggers an
automatic restart of the application.

For production, it is likely you will want to run the application under
"hypnotoad" behind nginx or similar.

=cut
