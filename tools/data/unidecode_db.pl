#!/usr/bin/env perl
use exact;
use Config::App;
use Util::CommandLine qw( options pod2usage );
use Text::Unidecode 'unidecode';
use CBQZ;

my $settings = options( qw( decode|d nbsp|n report|r save|s ) );
my $dq       = CBQZ->new->dq;
my $fields   = {
    question => [ qw( question answer marked  ) ],
    quiz     => [ qw( meet name quizmaster    ) ],
    user     => [ qw( username realname email ) ],
};

$|++ unless ( $settings->{report} );

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

            $text =~ s/\s{2,}/ /g;
            $text =~ s/(^\s+|\s+$)//g;

            if ( $text ne $row->{$column} ) {
                if ( $settings->{report} ) {
                    say $table, ': ', $row->{ $table . '_id' };
                    say '-->[', $row->{$column}, ']<--';
                    say '-->[', $text, ']<--';
                    print "\n";
                }
                else {
                    print '.';
                }

                $dq
                    ->sql( 'UPDATE ' . $table . ' SET ' . $column . ' = ? WHERE ' . $table . '_id = ?' )
                    ->run( $text, $row->{ $table . '_id' } )
                if ( $settings->{save} );
            }
        }
    }
}

print "\n" unless ( $settings->{report} );

=head1 NAME

unidecode_db.pl - Find non-ASCII text in the database and convert to ASCII

=head1 SYNOPSIS

    unidecode_db.pl OPTIONS
        -d|decode
        -n|nbsp
        -r|report
        -s|save
        -h|help
        -m|man

=head1 DESCRIPTION

This program will find non-ASCII text in the database and convert to ASCII.

=head2 decode

C<decode> will translate non-ASCII text to an ASCII equivalent.

=head2 nbsp

C<nbsp> will translate HTML non-breaking space markup to actual spaces.

=head2 report

C<report> will display the changes to be made.

=head2 save

C<save> will actually save the changes to the database.
