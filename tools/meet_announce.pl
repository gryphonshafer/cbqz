#!/usr/bin/env perl
use exact;
use Util::CommandLine qw( options pod2usage );
use YAML::XS 'LoadFile';
use Template;

my $settings = options( qw( data|d=s number|n=i ) );
pod2usage unless ( $settings->{data} and $settings->{number} );

die "File specified not found\n" unless ( -f $settings->{data} );
my $data = LoadFile( $settings->{data} );

Template->new->process( 
    \*DATA, 
    { %{ $data->{default} }, %{ $data->{ $settings->{number} } } }, 
);

=head1 NAME

meet_announce.pl - Generate a quiz meet announcement email/message text

=head1 SYNOPSIS

    quiz_schedule.pl OPTIONS
        -d|data   YAML_FILE
        -n|number MEET_NUMBER
        -h|help
        -m|man

=head1 DESCRIPTION

This program will generate a quiz meet announcement text to be sent via an 
email template.

=cut

__END__
This is a [% meet %] test.

Below is all the information you could ever want for the upcoming quiz meet.
    
    *Please let us know if anything looks amiss or if you have any questions.* 
    *It's much easier for us to fix any errors far in advance of the meet.* 

#Meet Documents Attached:
+ [% meet %] Meet Schedule.xlsx (change the dropdown to select your team name and all your team's prelims will be highlighted)
+ [% meet %] Meet Schedule.pdf
+ [% meet %] Roster.xlsx (*for Gryphon!!*)
+ [% meet %] Roster.pdf

    *the documents are also linked on the website (www.pnwquizzing.com).  

#Entering and Leaving Quiz Rooms
+ Please enter and leave quiz rooms **only between quizzes**.
+ If you absolutely must enter during a quiz, it *must be between questions*, and not while a quizzer is answering.  
+ Please hold each other accountable for this!   

#Backup Acme Equipment
+ If you have Acme quiz equipment, please label it and bring it as a backup for the district's Acme quiz equipment.  

#MEET DATE, LOCATION, ADDRESS
[% meet %] will occur on [% date %] and will be held at [% location %] which is located at [% address %].

#LUNCH INFORMATION
[% IF lunch == 'No' %] + There will be no lunch provided at the church.
[% ELSE %] + There will be lunch provided at the church. [%- END -%]

#LEADERSHIP MEETING
[% IF mtg == 'No' %] + There will be no leadership meeting during lunch.
[% ELSE %] + There will be a leadership meting during lunch in [% mtg_room %]. [%- END -%]

#MISCELLANEOUS INFORMATION
[% note1 %]
[%- note2 -%]

#QUIZ MEET COMPETITION INFORMATION
+ There are [% churches %] churches participating in [% meet %]
+ There are [% teams %] teams participating in [% meet %].
+ Each team will have [% prelims %] preliminary quizzes.
+ These preliminary quizzes will occur across [% rooms %] quiz rooms.
+ Each team will have at least [% min %] total quizzes.
+ Each team will have at most [% max %] total quizzes.
+ There are [% quizzers %] quizzers participating in [% meet %].

#OFFICIALS
##STATISTICIAN
The statistician for the meet is: [% stats %]

##MEET DIRECTOR
The meet director is: [% meet_director %]

##SOCIAL MEDIA
+ The new podcast for quizzing is live! Search "Inside Quizzing iTunes" and you'll find it!')
+ The email address of the podcast is [% email_pod %].  You can email questions and feedback.
+ The Twitter account of the podcast is [% tw_pod %].
+ Pacific Northwest Bible Quizzing's Twitter account is [% twitter %].
+ Pacific Northwest Bible Quizzing's Instagram account is [% insta %].
