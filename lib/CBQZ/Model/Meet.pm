package CBQZ::Model::Meet;

use Moose;
use exact;

extends 'CBQZ::Model';

my $skip_room_sort_matrix = {
    3 => [ 10 ],
    5 => [ 14, 16, 21 ],
    6 => [ 5, 11, 18 ],
};

sub build_draw ( $self, $settings ) {
    my $team_id      = 0;
    my $teams_matrix = [
        map { { name => $_, id => $team_id++ } }
        @{ $settings->{teams} }
    ];

    my $skip_room_sort_on = (
        @{ $settings->{teams} } / $settings->{rooms} == int( @{ $settings->{teams} } / $settings->{rooms} )
    ) ? $skip_room_sort_matrix->{ $settings->{rooms} } : [];

    $teams_matrix = [
        map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [ $_, rand ] } @$teams_matrix
    ] unless ( $settings->{norandom} );

    # calculate quiz counts
    my $remainder = @$teams_matrix * $settings->{quizzes} % 3;
    my $three_team_quizzes = int( @$teams_matrix * $settings->{quizzes} / 3 );
    $three_team_quizzes-- if ( $remainder == 1 );
    my $two_team_quizzes = ( $remainder == 1 ) ? 2 : ( $remainder == 2 ) ? 1 : 0;

    # generate meet schema
    my ( $meet, @quizzes );
    for ( 1 .. $three_team_quizzes + $two_team_quizzes ) {
        my $set = [];
        for ( 1 .. $settings->{rooms} ) {
            my $quiz = [ (undef) x 3 ];
            push( @$set, $quiz );
            push( @quizzes, $quiz );
            last if ( @quizzes >= $three_team_quizzes + $two_team_quizzes );
        }
        push( @$meet, $set );
        last if ( @quizzes >= $three_team_quizzes + $two_team_quizzes );
    }
    if ($two_team_quizzes) {
        @quizzes = map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [ $_, rand ] } @quizzes
            unless ( $settings->{norandom} );

        pop @{ $quizzes[$_] } for ( 0 .. $two_team_quizzes - 1 );
    }

    my $set_count = 0;
    for my $set (@$meet) {
        $set_count++;
        my @already_scheduled_teams;
        for my $room ( 1 .. $settings->{rooms} ) {
            my $quiz = $set->[ $room - 1 ];
            next unless $quiz;
            for my $position ( 0 .. @$quiz - 1 ) {
                my @available_teams = grep {
                    my $team = $_;
                    not grep { $team->{id} == $_->{id} } @already_scheduled_teams;
                } @$teams_matrix;

                E->throw('Insufficient teams to fill quiz set; reduce rooms or rerun') unless @available_teams;

                my @quiz_team_names = map { $_->{name} } grep { defined } @$quiz;
                if (@quiz_team_names) {
                    for my $team (@available_teams) {
                        $team->{seen_team_weight} = 0;
                        $team->{seen_team_weight} += $team->{teams}{$_} || 0 for (@quiz_team_names);
                    }
                }

                my ($selected_team) = sort {
                    ( $a->{quizzes}              || 0 ) <=> ( $b->{quizzes}              || 0 ) ||
                    ( $a->{seen_team_weight}     || 0 ) <=> ( $b->{seen_team_weight}     || 0 ) ||
                    (
                        ( grep { $set_count == $_ } @$skip_room_sort_on )
                            ? 0
                            : ( $a->{rooms}{$room} || 0 ) <=> ( $b->{rooms}{$room} || 0 )
                    ) ||
                    ( $a->{positions}{$position} || 0 ) <=> ( $b->{positions}{$position} || 0 ) ||
                    $a->{id} <=> $b->{id}
                } @available_teams;

                E->throw('Unable to select a team via algorithm; reduce rooms or rerun') unless $selected_team;

                $quiz->[$position] = $selected_team;
                push( @already_scheduled_teams, $selected_team );

                $selected_team->{rooms}{$room}++;
                $selected_team->{positions}{$position}++;
                $selected_team->{quizzes}++;
            }

            my @quiz_team_names = map { $_->{name} } @$quiz;
            for my $team (@$quiz) {
                $team->{teams}{$_}++ for ( grep { $team->{name} ne $_ } @quiz_team_names );
            }
        }
    }

    unless ( $settings->{norandom} ) {
        # randomize sets
        my $last_set = pop @$meet;
        $meet = [ ( map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [ $_, rand ] } @$meet ), $last_set ];

        # randomize the rooms
        my $room_map;
        for my $set (@$meet) {
            $room_map //= [ map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [ $_ - 1, rand ] } 1 .. @$set ];
            next unless ( @$set == @$room_map );
            $set = [ map { $set->[ $room_map->[$_] ] } ( 0 .. @$room_map - 1 ) ];
        }
    }

    my $quiz_counts;
    for my $set (@$meet) {
        for my $quiz (@$set) {
            # clean meet data set
            $quiz = [ map { $_->{name} } @$quiz ];

            my $quiz_key = join( '', sort @$quiz );
            $quiz_counts->{$quiz_key}{count}++;
            $quiz_counts->{$quiz_key}{quiz} = $quiz;
        }
    }

    my $quiz_stats;
    for my $quiz_key ( sort keys %$quiz_counts ) {
        push( @{ $quiz_stats->{ $quiz_counts->{$quiz_key}{count} } }, $quiz_counts->{$quiz_key}{quiz} );
    }

    my $team_stats = [
        sort { $a->{name} cmp $b->{name} }
        map {
            my $team    = $_;
            my $quizzes = 0;
            my $rooms   = { map {
                $quizzes += $team->{rooms}{$_};
                $_ + 1 => $team->{rooms}{$_};
            } keys %{ $team->{rooms} } };

            +{
                name    => $team->{name},
                rooms   => $rooms,
                teams   => \%{ $team->{teams} },
                quizzes => $quizzes,
            };
        } @$teams_matrix
    ];

    return $meet, $team_stats, $quiz_stats;
}

__PACKAGE__->meta->make_immutable;

1;
