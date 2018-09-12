package CBQZ::Model::Question;

use Moose;
use MooseX::ClassAttribute;
use exact;
use Mojo::DOM;
use Time::Out 'timeout';
use Try::Tiny;
use CBQZ::Model::QuestionSet;

extends 'CBQZ::Model';

class_has 'schema_name' => ( isa => 'Str', is => 'ro', default => 'Question' );

sub is_owned_by ( $self, $user ) {
    return (
        $user->obj->id and $self->obj->question_set->user_id and
        $user->obj->id == $self->obj->question_set->user_id
    ) ? 1 : 0;
}

sub is_shared_to ( $self, $user ) {
    return (
        $user->obj->id and $self->obj->question_set->user_id and
        grep { $_->question_set_id == $self->obj->question_set->id }
            $user->obj->user_question_sets->search({ type => 'share' })->all
    ) ? 1 : 0;
}

sub is_usable_by ( $self, $user ) {
    return ( $self->is_owned_by($user) or $self->is_shared_to($user) ) ? 1 : 0;
}

sub is_shared_set ($self) {
    $self->obj->question_set->user_question_sets->search({ type => 'share' })->count;
}

{
    my $material         = [{}];
    my @lower_case_words = ();

    my $words = sub ($text) {
        $text =~ s/<[^>]+>//g;
        $text =~ s/\W/ /g;
        $text =~ s/\s+/ /g;
        $text =~ s/(^\s+|\s+$)//g;
        return [ split( /\s/, $text ) ];
    };

    my $first_5 = sub ($text) {
        my @text = @{ $words->($text) };
        return
            join( ' ', grep { $_ } @text[ 0 .. 4 ] ),
            join( ' ', grep { $_ } @text[ 5 .. @text - 1 ] );
    };

    my $get_2_verses = sub ($data) {
        my @verses =
            sort { $a->{verse} <=> $b->{verse} }
            grep {
                $_->{book} eq $data->{book} and
                $_->{chapter} == $data->{chapter} and
                (
                    $_->{verse} == $data->{verse} or
                    $_->{verse} == $data->{verse} + 1
                )
            } @$material;

        E->throw('Unable to lookup material based on reference') unless ( $verses[0]->{text} );
        return @verses;
    };

    my $case = sub ($text) {
        $text =~ s/^((?:<[^>]+>)|\W)*(\w)/ ($2) ? ( $1 || '' ) . uc $2 : uc $1 /e;
        return $text;
    };

    my $fix = sub ($text) {
        $text =~ s/[-,;:]+(?:<[^>]+>)*$//;
        $text = Mojo::DOM->new($text)->to_string;
        $text =~ s/&quot;/"/g;
        $text =~ s/&#39;/'/g;

        return $text;
    };

    my $prep_text_re = sub ($text) {
        $text =~ s/\[[^\]]*\]//g;
        $text =~ s/\s+/ /g;
        $text =~ s/[^\w\s]+//g;
        $text =~ s/(\w)/$1(?:<[^>]+>)*['-]*(?:<[^>]+>)*/g;
        $text =~ s/(?:^\s+|\s+$)//g;
        $text =~ s/\s/(?:<[^>]+>|\\W)+/g;
        $text = '(?:[\'\"])?(?:<[^>]+>)*\b' . $text . '\b';

        return $text;
    };

    my $search = sub ( $text, $book, $chapter, $verse, $range ) {
        $text = $prep_text_re->($text);

        my @matches =
            map { $_->[0] }
            sort { $a->[1] <=> $b->[1] }
            map { [ $_, abs( $verse - $_->{verse} ) ] }
            grep {
                $_->{book} eq $book and
                $_->{chapter} eq $chapter and
                $_->{verse} >= $verse - $range and
                $_->{verse} <= $verse + $range
            }
            @$material;

        my @filtered_matches;
        timeout 2 => sub {
            @filtered_matches =
                grep { defined }
                map {
                    ( $_->{text} =~ /($text)/i ) ? { verse => $_, match => $fix->($1) } : undef
                }
                @matches;
        };

        return @filtered_matches;
    };

    my $save_back_match = sub ( $original, $match ) {
        my @brackets;
        push( @brackets, $1 ) while ( $original =~ /\[([^\]]*)\]/g );
        @brackets = map { s/[.!?]$//; $_ } @brackets;

        return join( ' ', grep { defined } map {
            my $text = $prep_text_re->($_);
            my $section = ( $match =~ s|^($text(?:\S+)?)||i ) ? $1 : undef;
            $section, ( (@brackets) ? '[' . shift(@brackets) . ']' : undef );
        } split( /\[[^\]]*\]/, $original ) ) . $match;
    };

    my $process_question = sub ( $data, $skip_casing, $range, $skip_interogative ) {
        $range //= 5;

        my $int;
        unless ($skip_interogative) {
            if ( $data->{question} =~ s/(\W*\b(?:who|what|when|where|why|how|whom|whose|which)\b\W*)$//i ) {
                $int->{phrase} = lc $1;
                $int->{pos}    = 'aft';
            }
            elsif ( $data->{question} =~ s/^(\W*\b(?:who|what|when|where|why|how|whom|whose|which)\b\W*)//i ) {
                $int->{phrase} = lc $1;
                $int->{phrase} = ucfirst $1 unless ($skip_casing);
                $int->{pos}    = 'fore';
            }
        }

        my @matches = $search->( @$data{ qw( question book chapter verse ) }, $range );

        E->throw('Multiple question matches found where only 1 expected') if ( @matches > 1 );
        E->throw('Unable to find question match') if ( @matches == 0 );

        my $match = $matches[0]->{match};
        if ( $int->{phrase} ) {
            if ( $int->{pos} eq 'aft' ) {
                $match = $case->($match) unless ($skip_casing);
                $match .= $int->{phrase};
            }
            else {
                $match = $int->{phrase} . $match;
            }
        }
        $data->{question} = $save_back_match->( $data->{question}, $match );

        if ( $skip_casing and $skip_casing eq 'answer_only' ) {
            my $first_word = lc $words->( $data->{question} )->[0];
            $data->{question} = lcfirst $data->{question} if ( grep { $first_word eq $_ } @lower_case_words );
        }

        @matches = $search->( @$data{ qw( answer book chapter verse ) }, $range );
        E->throw('Unable to find answer match') if ( @matches == 0 );

        $match = $matches[0]->{match};
        $match = $case->($match) unless ( $skip_casing and $skip_casing ne 'answer_only' );
        $data->{answer} = $save_back_match->( $data->{answer}, $match );

        return $data;
    };

    my $type_fork = sub ($data) {
        for ( qw( question answer ) ) {
            $data->{$_} =~ s/<[^>]*>//g if ( defined $data->{$_} );
        }

        if ( $data->{type} eq 'INT' or $data->{type} eq 'MA' ) {
            $data = $process_question->( $data, 0, 5, 0 );
            return unless ($data);
            $data->{question} .= '?' unless ( $data->{question} =~ /\?$/ );
        }
        elsif (
            $data->{type} eq 'CR' or $data->{type} eq 'CVR' or
            $data->{type} eq 'MACR' or $data->{type} eq 'MACVR'
        ) {
            $data->{question} =~ s/ac\w*\sto\s+(\d\s+)?\w+[,\s]+c\w*\s*\d+(?:[,\s]+v\w*\s*\d+)?[\s:,]*//i;
            $data = $process_question->(
                $data,
                'answer_only',
                ( ( $data->{type} eq 'CVR' or $data->{type} eq 'MACVR' ) ? 0 : 5 ),
                0,
            );
            return unless ($data);
            $data->{question} =
                'According to ' . $data->{book} . ', chapter ' . $data->{chapter} .
                ( ( $data->{type} eq 'CVR' or $data->{type} eq 'MACVR' ) ? ', verse ' . $data->{verse} : '' ) .
                ', ' . $data->{question};
            $data->{question} .= '?' unless ( $data->{question} =~ /\?$/ );
        }
        elsif ( $data->{type} eq 'Q' or $data->{type} eq 'Q2V' ) {
            my @verses = $get_2_verses->($data);

            $data->{question} = 'Quote ' . $data->{book} . ', chapter ' . $data->{chapter} . ', ' .
                (
                    ( $data->{type} eq 'Q' )
                        ? 'verse ' . $data->{verse}
                        : 'verses ' . $data->{verse} . ' and ' . ( $data->{verse} + 1 )
                ) . '.';

            $data->{answer} = ( $data->{type} eq 'Q' )
                ? $verses[0]->{text}
                : join( ' ', map { $_->{text} } @verses );
        }
        elsif ( $data->{type} eq 'FTV' or $data->{type} eq 'F2V' ) {
            my @verses        = $get_2_verses->($data);
            my ($punctuation) = $verses[0]->{text} =~ /([\~\!\(\)\-\:\;\'\"\,\.\?]+)$/;

            ( $data->{question}, $data->{answer} ) = $first_5->( $verses[0]->{text} );

            $data = $process_question->( $data, 1, 0, 1 );
            return unless ($data);

            $data->{question} .= '...' unless ( $data->{question} =~ /\.{3}$/ );
            $data->{answer} = '...' . $data->{answer} unless ( $data->{answer} =~ /^\.{3}/ );
            $data->{answer} .= ( $punctuation || '' ) . ' ' . $verses[1]->{text} if ( $data->{type} eq 'F2V' );
        }
        elsif ( $data->{type} eq 'FT' or $data->{type} eq 'FTN' ) {
            my $quote_off  = sub { while ( $_[0] =~ s/(<[^">]*)"([^"]+)"/$1'$2'/g ) {} };
            my $quote_back = sub { while ( $_[0] =~ s/(<[^'>]*)'([^']+)'/$1"$2"/g ) {} };

            my @verses        = $get_2_verses->($data);
            my ($punctuation) = $verses[0]->{text} =~ /([\~\!\(\)\-\:\;\'\"\,\.\?]+)$/;

            $quote_off->( $verses[0]->{text} );
            $verses[0]->{text} =~ s/^[^"]+"//;
            $quote_back->( $verses[0]->{text} );

            ( $data->{question}, $data->{answer} ) = $first_5->( $verses[0]->{text} );

            $data = $process_question->( $data, 1, 0, 1 );
            return unless ($data);

            $data->{question} .= '...' unless ( $data->{question} =~ /\.{3}$/ );
            $data->{answer} = '...' . $data->{answer} unless ( $data->{answer} =~ /^\.{3}/ );
            $data->{answer} .= ( $punctuation || '' ) . ' ' . $verses[1]->{text} if ( $data->{type} eq 'FTN' );

            $quote_off->( $data->{answer} );
            $data->{answer} =~ s/".*//;
            $quote_back->( $data->{answer} );
        }
        else {
            E->throw('Auto-text not supported for question type');
        }

        $data->{answer} =~ s/[,:\-]+$//g;
        $data->{answer} .= '.' unless ( $data->{answer} =~ /[.!?]['"]*$/ );

        return $data;
    };

    sub auto_text ( $self, $material_set, $question = undef ) {
        $question = $self->data if ( not $question and $self->obj );

        try {
            $material = $material_set->load_material->material;
        }
        catch {
            E->throw('Unable to load material from provided material set');
        };

        my %lower_case_words =
            map { $_ => 1 }
            grep { /^[a-z]/ }
            map { @{ $words->( $_->{text} ) } }
            @$material;
        @lower_case_words = sort keys %lower_case_words;

        try {
            $question = $type_fork->($question);
        }
        catch {
            $question->{error} = 'Auto-text error: ' . ( split(/\n/) )[0];
        };

        return $question;
    }
}

sub calculate_score ( $self, $material_set, $question = undef ) {
    $question = $self->data if ( not $question and $self->obj );

    my $clean = sub {
        my ($text) = @_;
        $text =~ s/<[^>]*>//g;
        $text =~ s/\[[^\]]*\]//g;
        $text =~ s/[^a-z0-9 ]+//gi;
        return lc($text);
    };

    my $words = sub {
        return scalar( split( /\s+/, $_[0] ) );
    };

    my $chars = sub {
        return scalar( grep { /\S/ } split( '', $_[0] ) );
    };

    my $de_int = sub {
        my ($text) = @_;
        $text =~ s/\s+(who|what|when|where|why|how|whom|whose|which)$// or
            $text =~ s/^(who|what|when|where|why|how|whom|whose|which)\s+//;
        return $text;
    };

    my %verses;
    for ( @{ $material_set->load_material->material } ) {
        my $clean = $clean->( $_->{text} );
        push( @{ $verses{all} }, $clean );
        push( @{ $verses{key} }, $clean ) if ( $_->{key_class} );
        push( @{ $verses{ $_->{book} . ' ' . $_->{chapter} } }, $clean );
    }

    my $common_words = sub {
        my ( $words, $type ) = @_;
        $type //= 'all';

        my @words = split( /\s+/, $words );
        my @active;

        while (@words) {
            push( @active, shift @words );
            my $phrase = join( ' ', @active );
            last if ( scalar( grep { index( $_, $phrase ) > -1 } @{ $verses{$type} } ) < 2 );
        }

        return scalar @active;
    };

    my $question_text = $clean->( $question->{question} );
    my $answer_text   = $clean->( $question->{answer}   );

    my $score;
    if ( $question->{type} eq 'INT' ) {
        $score =
            $common_words->( $de_int->($question_text) ) ** 1.4 +
            ( $words->($question_text) + $words->($answer_text) ) / 24;
    }
    elsif ( $question->{type} eq 'MA' ) {
        $score =
            $common_words->( $de_int->($question_text) ) ** 1.6 +
            ( $chars->($question_text) + $chars->($answer_text) ) / 140;
    }
    elsif ( $question->{type} =~ /^F/ ) {
        $score =
            $common_words->( $de_int->($question_text), 'key' ) ** 1.9 +
            ( $words->($question_text) + $words->($answer_text) ) / 28;
    }
    elsif ( $question->{type} =~ /^Q/ ) {
        $score =
            $common_words->( $de_int->($question_text) ) ** 1.5 +
            ( $words->($question_text) + $words->($answer_text) ) / 20;
    }
    elsif ( $question->{type} =~ /CV?R/ ) {
        ( $question_text = $question->{question} )
            =~ s/ac\w*\sto\s+(\d\s+)?\w+[,\s]+c\w*\s*\d+(?:[,\s]+v\w*\s*\d+)?[\s:,]*//i;
        $question_text = $clean->($question_text);

        if ( $question->{type} =~ /CR/ ) {
            $score =
                $common_words->(
                    $de_int->($question_text),
                    $question->{book} . ' ' . $question->{chapter},
                ) ** 1.7 +
                ( $words->($question_text) + $words->($answer_text) ) / 8;
        }
        elsif ( $question->{type} =~ /CVR/ ) {
            $score =
                $common_words->( $de_int->($question_text) ) ** 1.2 +
                ( $words->($question_text) + $words->($answer_text) ) / 8;
        }
    }
    elsif ( $question->{type} eq 'SIT' ) {
        $score =
            $common_words->( $de_int->($question_text) ) ** 1.4 +
            ( $words->($question_text) + $words->($answer_text) ) / 8;
    }

    $score = sprintf( '%3.1f', $score );
    $self->obj->update({ score => $score }) if ( $self->obj );
    return $score;
}

__PACKAGE__->meta->make_immutable;

1;
