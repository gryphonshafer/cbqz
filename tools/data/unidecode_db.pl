#!/usr/bin/env perl
use exact;
use Config::App;
use Util::CommandLine qw( options pod2usage );
use Text::Unidecode 'unidecode';
use CBQZ;

my $settings = options( qw( save|s decode|d nbsp|n ) );
my $dq       = CBQZ->new->dq;
my $fields   = {
    question => [ qw( question answer marked  ) ],
    quiz     => [ qw( meet name quizmaster    ) ],
    user     => [ qw( username realname email ) ],
};

for my $table ( sort keys %$fields ) {
    my $sth_read = $dq->sql(
        'SELECT ' . $table . '_id, ' . join( ', ', @{ $fields->{$table} } ) .
        ' FROM `' . $table . '`'
    )->run;

    while ( my $row = $sth_read->next ) {
        $row = $row->data;

        for my $column ( @{ $fields->{$table} } ) {
            next unless ( defined $row->{$column} );

            my $text = $row->{$column};
            $text = unidecode($text) if ( $settings->{decode} );
            $text =~ s/&nbsp;/ /g if ( $settings->{nbsp} );

            if ( $text ne $row->{$column} ) {
                say $table, ': ', $row->{ $table . '_id' };
                say $text, "\n";

                $dq
                    ->sql( 'UPDATE ' . $table . ' SET ' . $column . ' = ? WHERE ' . $table . '_id = ?' )
                    ->run( $row->{$column}, $row->{ $table . '_id' } )
                if ( $settings->{save} );
            }
        }
    }
}

=head1 NAME

unidecode_db.pl - Find non-ASCII text in the database and convert to ASCII

=head1 SYNOPSIS

    unidecode_db.pl OPTIONS
        -d|decode
        -n|nbsp
        -s|save
        -h|help
        -m|man

=head1 DESCRIPTION

This program will find non-ASCII text in the database and convert to ASCII.
