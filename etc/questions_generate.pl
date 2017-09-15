#!/usr/bin/env perl
use exact;
use open qw( :std :utf8 );
use Config::App;
use CBQZ;

my $dq = CBQZ->new->dq;

my $insert = $dq->sql(q{
    INSERT INTO question ( question_set_id, book, chapter, verse, question, answer, type )
    VALUES ( 1, ?, ?, ?, ?, ?, ? )
});

my $types = {
    key => [ qw( QT QTN FTV FT2V FT FTN ) ],
    non => [ qw( INT MA CR CVR MACR MACVR SIT ) ],
};

for my $verse ( @{ $dq->sql(q{
    SELECT book, chapter, verse, text, key_class, key_type
    FROM material
    WHERE material_set_id = 1
})->run->all({}) } ) {
    say $verse->{book} . ' ' . $verse->{chapter} . ':' . $verse->{verse};

    unless ( $verse->{key_class} ) {
        $insert->run(
            @$verse{ qw( book chapter verse ) },
            int( rand() * 1_000_000 ) . ' ' . $verse->{text},
            int( rand() * 1_000_000 ) . ' ' . $verse->{text},
            $types->{non}[ rand @{ $types->{non} } - 1 ],
        ) for ( 1 .. 4 );
    }
    else {
        $insert->run(
            @$verse{ qw( book chapter verse ) },
            int( rand() * 1_000_000 ) . ' ' . $verse->{text},
            int( rand() * 1_000_000 ) . ' ' . $verse->{text},
            $types->{non}[ rand @{ $types->{non} } - 1 ],
        ) for ( 1 .. 3 );

        $insert->run(
            @$verse{ qw( book chapter verse ) },
            int( rand() * 1_000_000 ) . ' ' . $verse->{text},
            int( rand() * 1_000_000 ) . ' ' . $verse->{text},
            $types->{key}[ rand @{ $types->{non} } - 1 ],
        ) for ( 1 .. 2 );
    }
}
