#!/usr/bin/env perl
use exact;
use open qw( :std :utf8 );
use Util::CommandLine qw( options pod2usage );
use Text::CSV_XS 'csv';
use Try::Tiny;
use Config::App;
use CBQZ::Model::MaterialSet;

my $settings = options( qw( kvl|k=s set|s=s ) );
pod2usage unless ( $settings->{kvl} and $settings->{set} );

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

my $material_set_id;
try {
    $material_set_id = CBQZ::Model::MaterialSet->new->load({ name => $settings->{set} })->obj->id;
};
die "Unable to find material set with specified name\n" unless ($material_set_id);

my $dq = CBQZ::Model::MaterialSet->new->dq;

$dq->sql('UPDATE material SET key_class = NULL, key_type = NULL WHERE material_set_id = ?')
    ->run($material_set_id);

my $update = $dq->sql(q{
    UPDATE material SET key_class = ?, key_type = ?
    WHERE material_set_id = ? AND book = ? AND chapter = ? AND verse = ?
});

for my $book ( keys %$kvl ) {
    for my $chapter ( keys %{ $kvl->{$book} } ) {
        for my $verse ( keys %{ $kvl->{$book}{$chapter} } ) {
            $update->run(
                @{ $kvl->{$book}{$chapter}{$verse} }{ qw( key_class key_type ) },
                $material_set_id, $book, $chapter, $verse,
            );
        }
    }
}

=head1 NAME

kvl_update.pl - Update key verse list data for a given materials set database

=head1 SYNOPSIS

    kvl_update.pl OPTIONS
        -k|kvl   KEY_VERSE_LIST_DATA_FILE
        -s|set   MATERIALS_SET_NAME
        -h|help
        -m|man
