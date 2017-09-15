#!/usr/bin/env perl
use exact;
use open qw( :std :utf8 );
use Config::App;
use CBQZ;

my $kvl;
if ( $ARGV[1] ) {
    open( my $kvl_fh, '<', $ARGV[1] || 'kvl.tsv' ) or die $!;
    while (<$kvl_fh>) {
        chomp;
        my ( $book, $chapter, @verses ) = split(/\t/);

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
}

my $dq = CBQZ->new->dq;

$dq->sql('INSERT INTO material_set (name) VALUES (?)')->run( $ARGV[2] or scalar( localtime() ) );
my $set_id = $dq->sql('SELECT last_insert_id()')->run->value;

my $ins_material = $dq->sql(q{
    INSERT INTO material (
        material_set_id, book, chapter, verse, text, key_class, key_type, is_new_para
    ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ? )
});

open( my $material_fh, '<', $ARGV[0] || 'material.tsv' ) or die $!;
while (<$material_fh>) {
    chomp;

    my $verse;
    @$verse{ qw( para key book chapter verse text ) } = split(/\t/);

    $ins_material->run(
        $set_id,
        @$verse{ qw( book chapter verse text ) },
        $kvl->{ $verse->{book} }{ $verse->{chapter} }{ $verse->{verse} }{key_class},
        $kvl->{ $verse->{book} }{ $verse->{chapter} }{ $verse->{verse} }{key_type},
        ( ( $verse->{para} =~ /^not_/ ) ? 0 : 1 ),
    );
}
