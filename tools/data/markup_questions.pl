#!/usr/bin/env perl
use exact;
use Config::App;
use Util::CommandLine qw( options pod2usage );
use Mojo::DOM;
use Time::Out 'timeout';
use CBQZ;

my $settings = options( qw( questions|q=s materials|m=s mark|k ) );
pod2usage unless ( $settings->{questions} and $settings->{materials} );

my $dq = CBQZ->new->dq;

my $q_set_id = $dq->sql('SELECT question_set_id FROM question_set WHERE name = ?')
    ->run( $settings->{questions} )->value;
die "Set name $settings->{questions} not found\n" unless ($q_set_id);

my $m_set_id = $dq->sql('SELECT material_set_id FROM material_set WHERE name = ?')
    ->run( $settings->{materials} )->value;
die "Set name $settings->{materials} not found\n" unless ($q_set_id);

my $material = $dq->sql('SELECT book, chapter, verse, text FROM material WHERE material_set_id = ?')
    ->run($m_set_id)->all({});

my $questions = $dq->get('question')->where( question_set_id => $q_set_id )->run;
while ( my $question = $questions->next ) {
    my $data = type_fork( { %{ $question->data } } );

    next if ( not $data and not $settings->{mark} );

    if ( not $data and $settings->{mark} ) {
        $question->cell( marked => 'Auto color markup failed' );
    }
    elsif ($data) {
        $question->cell( $_ => $data->{$_} ) for ( qw( question answer ) );
    }
    $question->save('question_id');
}

sub error ( $text, $data ) {
    print $text,
        '; QID: ', $data->{question_id},
        '; Ref: ', $data->{book}, ' ', $data->{chapter}, ':', $data->{verse},
        '; Type: ', $data->{type},
        "\n";
}

sub type_fork ($data) {
    $data->{$_} =~ s/<[^>]*>//g for ( qw( question answer ) );

    if ( $data->{type} eq 'INT' or $data->{type} eq 'MA' ) {
        $data = process_question( $data, 0, 5, 0 );
        return unless ($data);
        $data->{question} .= '?' unless ( $data->{question} =~ /\?$/ );
    }
    elsif (
        $data->{type} eq 'CR' or $data->{type} eq 'CVR' or
        $data->{type} eq 'MACR' or $data->{type} eq 'MACVR'
    ) {
        $data->{question} =~ s/ac\w*\sto\s+(\d\s+)?\w+[,\s]+c\w*\s*\d+(?:[,\s]+v\w*\s*\d+)?[\s:,]*//i;
        $data = process_question( $data, 1, ( ( $data->{type} eq 'CVR' or $data->{type} eq 'MACVR' ) ? 0 : 5 ), 0 );
        return unless ($data);
        $data->{question} =
            'According to ' . $data->{book} . ', chapter ' . $data->{chapter} .
            ( ( $data->{type} eq 'CVR' or $data->{type} eq 'MACVR' ) ? ', verse ' . $data->{verse} : '' ) .
            ', ' . $data->{question};
        $data->{question} .= '?' unless ( $data->{question} =~ /\?$/ );
    }
    elsif ( $data->{type} eq 'Q' or $data->{type} eq 'Q2V' ) {
        my @verses = get_2_verses($data);

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
        my @verses = get_2_verses($data);
        ( $data->{question}, $data->{answer} ) = first_5( $verses[0]->{text} );
        $data = process_question( $data, 1, 0, 1 );
        return unless ($data);

        $data->{question} .= '...' unless ( $data->{question} =~ /\.{3}$/ );
        $data->{answer} = '...' . $data->{answer} unless ( $data->{answer} =~ /^\.{3}/ );

        $data->{answer} .= ' ' . $verses[1]->{text} if ( $data->{type} eq 'F2V' );
    }
    elsif ( $data->{type} eq 'FT' or $data->{type} eq 'FTN' ) {
        my @verses = get_2_verses($data);
        ( $data->{question}, $data->{answer} ) = first_5( $data->{question} . ' ' . $data->{answer} );
        $data = process_question( $data, 1, 0, 1 );
        return unless ($data);

        $data->{question} .= '...' unless ( $data->{question} =~ /\.{3}$/ );
        $data->{answer} = '...' . $data->{answer} unless ( $data->{answer} =~ /^\.{3}/ );

        $data->{answer} .= ' ' . $verses[1]->{text} if ( $data->{type} eq 'FTN' );
    }
    else {
        error( 'Unexpected question type encountered', $data );
        return;
    }

    $data->{answer} .= '.' unless ( $data->{answer} =~ /[.!?]$/ );
    return $data;
}

sub regex ($text) {
    $text =~ s/\s+/ /g;
    $text =~ s/[^\w\s]+//g;
    $text =~ s/(\w)/$1(?:<[^>]+>)*['-]*(?:<[^>]+>)*/g;
    $text =~ s/(?:^\s+|\s+$)//g;
    $text =~ s/\s/(?:<[^>]+>|\\W)+/g;
    return '(?:<[^>]+>)*\b' . $text . '\b';
}

sub fix ($text) {
    $text =~ s/[-,;:]+(?:<[^>]+>)*$//;
    $text = Mojo::DOM->new($text)->to_string;
    $text =~ s/&quot;/"/g;
    $text =~ s/&#39;/'/g;

    return $text;
}

sub search ( $text, $book, $chapter, $verse, $range ) {
    $text = regex($text);

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
    timeout 5 => sub {
        @filtered_matches =
            grep { defined }
            map {
                ( $_->{text} =~ /($text)/i ) ? { verse => $_, match => fix($1) } : undef
            }
            @matches;
    };

    return @filtered_matches;
}

sub case ($text) {
    $text =~ s/^((?:<[^>]+>)|\W)*(\w)/ ($2) ? ( $1 || '' ) . uc $2 : uc $1 /e;
    return $text;
}

sub process_question ( $data, $skip_casing, $range, $skip_interogative ) {
    $range //= 5;

    my $int;
    unless ($skip_interogative) {
        if ( $data->{question} =~ s/(\W*\b(?:who|what|when|where|why|how|whom|whose)\b\W*)$//i ) {
            $int->{phrase} = lc $1;
            $int->{pos}    = 'aft';
        }
        elsif ( $data->{question} =~ s/^(\W*\b(?:who|what|when|where|why|how|whose)\b\W*)//i ) {
            $int->{phrase} = lc $1;
            $int->{phrase} = ucfirst $1 unless ($skip_casing);
            $int->{pos}    = 'fore';
        }
    }
    my @matches = search( @$data{ qw( question book chapter verse ) }, $range );
    if ( @matches > 1 ) {
        error( 'Multiple question matches found where only 1 expected', $data );
        return;
    }
    if ( @matches == 0 ) {
        error( 'Unable to find question match', $data );
        return;
    }
    my $match = $matches[0]->{match};
    if ( $int->{phrase} ) {
        if ( $int->{pos} eq 'aft' ) {
            $match = case($match) unless ($skip_casing);
            $match .= $int->{phrase};
        }
        else {
            $match = $int->{phrase} . $match;
        }
    }
    $data->{question} = $match;

    @matches = search( @$data{ qw( answer book chapter verse ) }, $range );
    if ( @matches == 0 ) {
        error( 'Unable to find answer match', $data );
        return;
    }

    $match = $matches[0]->{match};
    $match = case($match) unless ($skip_casing);
    $data->{answer} = $match;

    return $data;
}

sub get_2_verses ($data) {
    return
        sort { $a->{verse} <=> $b->{verse} }
        grep {
            $_->{book} eq $data->{book} and
            $_->{chapter} == $data->{chapter} and
            (
                $_->{verse} == $data->{verse} or
                $_->{verse} == $data->{verse} + 1
            )
        } @$material;
}

sub first_5 ($text) {
    $text    =~ s/<[^>]+>//g;
    $text    =~ s/\s+/ /g;
    $text    =~ s/(^\s+|\s+$)//g;
    my @text = split( /\s/, $text );

    return
        join( ' ', @text[ 0 .. 4 ] ),
        join( ' ', @text[ 5 .. @text - 1 ] );
}

=head1 NAME

markup_questions.pl - Add color markup to a plain-text questions set

=head1 SYNOPSIS

    markup_questions.pl OPTIONS
        -q|questions  QUESTIONS_SET_NAME
        -m|materials  MATERIAL_SET_NAME
        -k|mark       MARK_SKIPPED_QUESTIONS
        -h|help
        -m|man

=head1 DESCRIPTION

This program will add color markup to a plain-text questions set.
