#!/usr/bin/env perl
use exact;
use open qw( :std :utf8 );
use Util::CommandLine qw( options pod2usage );
use Config::App;
use Text::CSV_XS 'csv';
use CBQZ;

my $settings = options( qw( name|n=s kvl|k=s material|m=s ) );
pod2usage unless ( $settings->{name} and $settings->{kvl} and $settings->{material} );

my $kvl;
for ( @{ csv( in => $settings->{kvl} ) } ) {
    my ( $book, $chapter, @verses ) = @$_;

    for my $verse (@verses) {
        my $key_type = ( $verse =~ /\(([^)]+)\)/ ) ? $1 : undef;
        if ( $verse =~ /^(\d+)-(\d+)/ ) {
            for ( $1 .. $2 ) {
                $kvl->{$book}{$chapter}{$_} = { key_type => $key_type, key_class => 'range' };
            }
        }
        elsif ( $verse =~ /^(\d+)/ ) {
            $kvl->{$book}{$chapter}{$1} = { key_type => $key_type, key_class => 'solo' };
        }
    }
}

my $dq = CBQZ->new->dq;

$dq->sql('INSERT INTO material_set (name) VALUES (?)')->run( $settings->{name} );
my $set_id = $dq->sql('SELECT last_insert_id()')->run->value;

my $ins_material = $dq->sql(q{
    INSERT INTO material (
        material_set_id, book, chapter, verse, text, key_class, key_type, is_new_para
    ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ? )
});

for ( @{ csv( in => $settings->{material} ) } ) {
    my $verse;
    @$verse{ qw( para key book chapter verse text ) } = @$_;

    $ins_material->run(
        $set_id,
        @$verse{ qw( book chapter verse text ) },
        $kvl->{ $verse->{book} }{ $verse->{chapter} }{ $verse->{verse} }{key_class},
        $kvl->{ $verse->{book} }{ $verse->{chapter} }{ $verse->{verse} }{key_type},
        ( ( $verse->{para} =~ /^not_/ ) ? 0 : 1 ),
    );
}

=head1 NAME

material_load.pl - Load materials data into the database as a new materials set

=head1 SYNOPSIS

    material_load.pl OPTIONS
        -n|name     MATERIAL_SET_NAME
        -k|kvl      KEY_VERSE_LIST_DATA_FILE
        -m|material MATERIAL_DATA_FILE
        -h|help
        -m|man

=head1 DESCRIPTION

This program will load materials data into the database as a new materials set.
It requires a key verses list (KVL) data file and a materials data file along
with the name of the material set.

    material_load.pl \
        -n '2017 Corinthians' \
        -k 2017_Corinthians_KVL.csv \
        -m 2017_Corinthians_material.csv

=head2 Key Verses List Data File

The key verse list data file is expected to be comma-separated values file with
each row representing a chapter. The first column is the book name, the second
column is the chapter number, and subsequent columns are verses that are key.

    1 Corinthians,6,7,14,19-20 (QT)
    1 Corinthians,7,7,10-11 (FTN),19,21,22,23
    1 Corinthians,8,1 (FT),2-3,6,9,13
    1 Corinthians,9,19,22-23,24 (QT),25,26-27
    1 Corinthians,10,13,23-24,26 (FT),31,32-33

Ranges are specified with a dash. Key verse that are type constrained are
expected to have the type in parentheses following the verse number or verses
range.

=head2 Materials Data File

The materials data file is expected to be comma-separated values file with each
row representing a verse. The first column is either going to be "not_para" or
"para" indicating if the verse is the start of a new paragraph. The second
column is either going to be "not_key" or "key" indicating if the verse is a
key verse of any kind. The next 3 columns are book name, chapter, and verse
number.

The last column is the verse text, expected to be in HTML compliant with
what CBQZ internally expects the database content value to support. What this
means practically is that there's 3 HTML C<span> tags to markup text:

    <span class="unique_word">Word<span>
    <span class="unique_phrase">Some Phrase<span>
    <span class="unique_chapter">Word<span>
