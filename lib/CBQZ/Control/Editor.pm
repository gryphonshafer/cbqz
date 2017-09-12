package CBQZ::Control::Editor;

use exact;
use Mojo::Base 'Mojolicious::Controller';
use Try::Tiny;

sub path {
    my ($self) = @_;
    return $self->render( text => 'var cntlr = "' . $self->url_for->path('/editor') . '";' );
}

sub data {
    my ($self) = @_;

    my $material;
    push( @{ $material->{ $_->{book} }{ $_->{chapter} } }, $_ ) for (
        map {
            ( $_->{search} = lc( $_->{text} ) ) =~ s/<[^>]+>//g;
            $_->{search} =~ s/\W//g;
            $_;
        }
        @{
            $self->dq->sql(q{
                SELECT book, chapter, verse, text, key_class, key_type, is_new_para
                FROM material
                WHERE material_set_id = ?
                ORDER BY book, chapter, verse
            })->run(1)->all({})
        }
    );

    return $self->render( json => {
        question => {
            types => [ qw( INT MA CR CVR MACR MACVR QT QTN FTV FT2V FT FTN SIT ) ],
            books => [ sort { $a cmp $b } keys %$material ],
            ( map { $_ => undef } qw( type book chapter verse question answer ) ),
        },
        material => {
            data           => $material,
            search         => undef,
            matched_verses => undef,
            ( map { $_ => undef } map { $_, $_ . 's' } qw( book chapter verse ) ),
        },
        list => {
            books => [
                '1 Corinthians',
                '2 Corinthians',
            ],
            book => '1 Corinthians',
            chapters => [ 1, 2, 3, 4, 5 ],
            chapter => 3,
            questions => [
                { id => 1138, label => '1 (CR 0)' },
                { id => 1138, label => '1 (SQ 0)' },
                { id => 1138, label => '1 (SQ 0)' },
                { id => 1138, label => '1 (SQ 0)' },
                { id => 1138, label => '1 (SQ 0)' },
                { id => 1138, label => '2 (CVR 0)' },
                { id => 1138, label => '2 (MA 0)' },
                { id => 1138, label => '2 (SQ 0)' },
                { id => 1138, label => '2 (SQ 0)' },
                { id => 1138, label => '2 (SQ 0)' },
                { id => 1138, label => '2 (SQ 0)' },
                { id => 1138, label => '2 (SQ 0)' },
                { id => 1138, label => '3 (CR 0)' },
                { id => 1138, label => '3 (CR 0)' },
                { id => 1138, label => '3 (CVR 0)' },
                { id => 1138, label => '3 (SQ 0)' },
                { id => 1138, label => '3 (SQ 0)' },
                { id => 1138, label => '3 (SQ 0)' },
                { id => 1138, label => '3 (SQ 0)' },
                { id => 1138, label => '3 (SQ 0)' },
            ],
            question => '',
        },
    } );
}

sub save {
    my ($self) = @_;

    my $data = $self->req_body_json;
    $data->{verse}  = 42;
    $data->{answer} = 'This is <span class="unique_word">blue</span>. This is <span class="unique_phrase">special green</span>.';

    return $self->render( json => {
        question => $data,
    } );
}

1;
