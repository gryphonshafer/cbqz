#!/usr/bin/env perl
use exact;
use open qw( :std :utf8 );
use Config::App;
use Util::CommandLine qw( podhelp pod2usage );
use Parse::RecDescent;
use Data::Printer;

my $parser = Parse::RecDescent->new(q{
    word          : /[\w:]+/
    string_double : /"(([^"]*)(\\["\\])?)*"/ { \( '' . substr( $item[-1], 1, length( $item[-1] ) - 2 ) ) }
    string_single : /'(([^']*)(\\['\\])?)*'/ { \( '' . substr( $item[-1], 1, length( $item[-1] ) - 2 ) ) }
    string        : string_double | string_single
    block         : '[' ( call | string )(s) ']' { $item[2] }

    seq : word(s /\./) block(?) {
        pop @item if ( ref $item[-1] eq 'ARRAY' and @{ $item[-1] } == 0 );
        shift @item;
        [ map {@$_} @item ];
    }
    call : seq(s /\./) {
        shift @item;
        [ map {@$_} @item ];
    }
    execute : call(s /;/) {
        shift @item;
        [ map {@$_} @item ];
    }
});

my $calls = $parser->execute( join( ' ', @ARGV ) );

unless ($calls) {
    warn "Could not parse input\n";
    pod2usage;
}

p execute(@$_) for (@$calls);
exit;

sub execute {
    return ${ $_[0] } if ( ref $_[0] eq 'SCALAR' );
    my $obj;
    for my $seq (@_) {
        my @block = ( ref $seq->[-1] eq 'ARRAY' )
            ? map { execute(@$_) } map { ( ref $_ eq 'ARRAY' ) ? $_ : [$_] } @{ pop @$seq }
            : ();

        while (@$seq) {
            my $node = shift @$seq;

            unless ($obj) {
                $node = 'CBQZ::Model::' . join( '::', map { ucfirst($_) } split( '::', $node ) );
                eval "require $node";
                die $@ if ($@);
                "$node"->import;
                $obj = "$node"->new;
            }
            else {
                if ( not @block or @$seq ) {
                    $obj = $obj->$node();
                }
                else {
                    $obj = $obj->$node(@block);
                }
            }
        }
    }
    return $obj;
}

__END__
=pod

=head1 NAME

model.pl - Execute model calls using simplified grammar

=head1 SYNOPSIS

    model.pl INSTRUCTIONS | model.pl --help | model.pl --man

=head1 DESCRIPTION

This program will accept a set of INSTRUCTIONS that follow a simplified grammar
and run those instructions on the model layer. For example, these two lines
are equivalent:

    user.load[ 'name' 'old_name' ].change_name['new_name']
    CBQZ::Model::User->new->load( 'name' => 'old_name' )->change_name('new_name')

The first identifier found in a token is assumed to be the name of a model.
It is then instantiated with a blank C<new()> call. Use brackets for parentheses
when providing values to methods.

You can chain multiple calls with semicolons. The resulting output of each call
will be printed to STDOUT.

=cut
