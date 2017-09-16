#!/usr/bin/env perl
use exact;
# use open qw( :std :utf8 );
use Config::App;
use CBQZ;

my $dq = CBQZ->new->dq;

my $insert = $dq->sql(q{
    INSERT INTO question ( question_set_id, type, book, chapter, verse, question, answer )
    VALUES ( 1, ?, ?, ?, ?, ?, ? )
});

for my $file (@ARGV) {
    open( my $input, '<', $file ) or die $!;
    while (<$input>) {
        s/[\x91\x92]/'/g;
        s/[\x93\x94]/"/g;
        s/\x97/\./g;
        s/\xBB/>/g;
        s/[\r\n]//g;

        my $line;
        @$line{ qw( type book chapter verse question answer ) } = split(/\t/);
        next unless ( $line->{answer} );
        next unless ( $line->{book} eq '1 Corinthians' );
        next unless ( $line->{chapter} <= 4 );

        $line->{type} = 'MACR' if ( $line->{type} eq 'CRMA' );
        $line->{type} = 'MACVR' if ( $line->{type} eq 'CVRMA' );
        $line->{type} = 'Q' if ( $line->{type} eq 'QT' );

        $line->{verse} =~ s/\D.*$//g;

        $line->{question} =~ s/^"|"$//g;
        $line->{answer}   =~ s/^"|"$//g;
        $line->{question} =~ s/^\s+|\s+$//g;
        $line->{answer}   =~ s/^\s+|\s+$//g;

        $line->{question} =~ s/^Q:\s+//i;
        $line->{answer}   =~ s/^A:\s+//i;

        $line->{question} = "According to $line->{book}, chapter $line->{chapter}, $line->{question}"
            if ( $line->{type} eq 'MACR' or $line->{type} eq 'CR' );
        $line->{question} = "According to $line->{book}, chapter $line->{chapter}, verse $line->{verse}, $line->{question}"
            if ( $line->{type} eq 'MACVR' or $line->{type} eq 'CVR' );

        $insert->run( @$line{ qw( type book chapter verse question answer ) } );
    }
}
