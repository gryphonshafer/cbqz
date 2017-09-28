package CBQZ::Model::Gateway;

use Moose;
use MooseX::ClassAttribute;
use Mojo::URL;
use Mojo::DOM;
use CBQZ::Util::File qw( filename spurt slurp );

extends 'CBQZ::Model';

class_has _summary_dom => ( isa => 'Mojo::DOM', is => 'ro', lazy => 1, default => sub {
    my ($self) = @_;

    my $file = filename(
        $self->config->get( qw( config_app root_dir ) ),
        $self->config->get('data'),
        'gateway',
        'niv',
        'summary.html',
    );

    my $html;
    unless ( -f $file ) {
        $html = $self->ua->get('https://www.biblegateway.com/passage/?version=NIV&search=')->result->text;
        spurt( $file, $html );
    }
    else {
        $html = slurp($file);
    }

    return Mojo::DOM->new($html);
} );

class_has translations => ( isa => 'ArrayRef', is => 'ro', lazy => 1, default => sub {
    my ($self) = @_;

    my ( $language, $translations );
    for my $element (
        $self->_summary_dom->find(q{
            div.search-translation select.search-translation-select option
        })->each
    ) {
        my $attr = $element->attr;

        if ( ( $attr->{class} || '' ) eq 'spacer' ) {
            next;
        }
        elsif ( ( $attr->{class} || '' ) eq 'lang' ) {
            ( my $name = $element->text ) =~ s/\s*\(([^\)]+)\)\s*//;
            my $value = $1;

            my $dash = chr(8212);
            $name =~ s/\s*$dash\s*//g;

            $language = {
                value => $value,
                name  => $name,
            };
        }
        else {
            ( my $name = $element->text ) =~ s/\s*\([^\)]*\)\s*$//;

            push( @$translations, {
                value    => $attr->{value},
                name     => $name,
                language => $language,
            } );
        }
    }

    return $translations;
} );

class_has books => ( isa => 'HashRef', is => 'ro', lazy => 1, default => sub {
    my ($self) = @_;

    return {
        map {
            $_->at('td.book-name')->text => $_->at('td.chapters a:last-child')->text
        } $self->_summary_dom->find('table#booklist tr')->each
    };
} );

sub translations_for_language {
    my ( $self, $language ) = @_;
    $language = lc($language);

    return [ grep {
        lc( $_->{language}{name} ) eq $language or
        lc( $_->{language}{value} ) eq $language
    } @{ $self->translations } ];
}

sub raw_chapter {
    my ( $self, $book_chapter, $translation ) = @_;
    $translation //= 'NIV';

    E->throw('Book/chapter provided does not look legitimate')
        unless ( $book_chapter and $book_chapter =~ /\w\s+\d+\s*$/ );

    $book_chapter =~ /^\s*(?<book>.+)\s+(?<chapter>\d+)\s*$/;

    my $file = filename(
        $self->config->get( qw( config_app root_dir ) ),
        $self->config->get('data'),
        'gateway',
        $translation,
        $+{book},
        $+{chapter} . '.html',
    );

    return slurp($file) if ( -f $file );

    my $html = $self->ua->get(
        Mojo::URL
            ->new('https://www.biblegateway.com/passage/')
            ->query( version => $translation, search => $book_chapter )
            ->to_string
    )->result->text;

    spurt( $file, $html );
    return $html;
}

sub chapter_as_obml {
    my ( $self, $book_chapter, $translation ) = @_;
    $translation //= 'NIV';

    my $passage = Mojo::DOM
        ->new( $self->raw_chapter( $book_chapter, $translation ) )
        ->at('div.passage-bible div.passage-content div:first-child');

    my $i = sub {
        my ($node) = @_;
        $node->find('i')->each( sub {
            $_->replace( '^' . $_->text . '^' );
        } );
        return $node->all_text;
    };

    my $footnotes;
    if ( my $div_footnotes = $passage->at('div.footnotes') ) {
        $footnotes = {
            map {
                $_->at('a')->attr('href') => $i->( $_->at('span') )
            } $div_footnotes->find('ol li')->each
        };
        $div_footnotes->remove;
    }

    my $crossrefs;
    if ( my $div_crossrefs = $passage->at('div.crossrefs') ) {
        $crossrefs = {
            map {
                $_->at('a:first-child')->attr('href') => $self->parse_out_refs(
                    $_->at('a:last-child')->attr('data-bibleref')
                )
            } $div_crossrefs->find('ol li')->each
        };
        $div_crossrefs->remove;
    }

    return 42;
}

sub verses_from_books {
    my ( $self, $books, $translation ) = @_;
    $translation //= 'NIV';

    E->throw('First parameter must be an arrayref containing books')
        unless ( ref $books eq 'ARRAY' and @$books );

    for my $book (@$books) {
        E->throw("Didn't recognize $book as a formal book name") unless ( $self->books->{$book} );
    }

    my ( $content, $headers );
    for my $book (@$books) {
        for my $chapter ( 1 .. $self->books->{$book} ) {
            my $dom = Mojo::DOM
                ->new( $self->raw_chapter( "$book $chapter", $translation ) )
                ->at('div.passage-bible div.passage-content div:first-child');

            for my $verse ( $dom->find('h3 span.text, p span.text')->each ) {
                $verse->attr('class') =~ /\w\-\d+\-(?<verse>\d+)$/;
                push(
                    @{ ( ( $verse->parent->tag eq 'h3' ) ? $headers : $content )->{$book}{$chapter}{ $+{verse} } },
                    $verse->text,
                );
            }
        }
    }

    for my $book ( sort { $a cmp $b } keys %$content ) {
        for my $chapter ( sort { $a <=> $b } keys %{ $content->{$book} } ) {
            for my $verse ( sort { $a <=> $b } keys %{ $content->{$book}{$chapter} } ) {
                print join( "\t",
                    ( ( $headers->{$book}{$chapter}{$verse} ) ? 1 : 0 ),
                    $book,
                    $chapter,
                    $verse,
                    join( ' ', @{ $content->{$book}{$chapter}{$verse} } ),
                ), "\n";
            }
        }
    }
}

sub verses {
    my ( $self, $book_chapter, $translation ) = @_;
    $translation //= 'NIV';

    my $dom = Mojo::DOM
        ->new( $self->raw_chapter( $book_chapter, $translation ) )
        ->at('div.passage-bible div.passage-content div:first-child');

    for my $verse ( $dom->find('p span.text')->each ) {
        print $verse->attr('class'), "\n";
        print $verse->text, "\n";
    }

    return 42;
}

__PACKAGE__->meta->make_immutable;

1;
