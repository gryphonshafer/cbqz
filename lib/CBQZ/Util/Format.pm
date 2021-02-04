package CBQZ::Util::Format;

use exact;
use Date::Parse 'str2time';
use Date::Format 'time2str';
use DateTime;
use DateTime::TimeZone;

require Exporter;

our @ISA       = 'Exporter';
our @EXPORT_OK = qw( log_date date_time_ansi canonical_date_time zulu_date_time );

{
    my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    sub log_date ( $this_time = time ) {
        my ( $year, $month, @time_bits ) = reverse( ( localtime($this_time) )[ 0 .. 5 ] );
        return sprintf( '%3s %2d %2d:%02d:%02d %4d', $abbr[$month], @time_bits, ( $year + 1900 ) );
    }
}

sub date_time_ansi ( $this_time = time ) {
    my ( $year, $month, @time_bits ) = reverse( ( localtime($this_time) )[ 0 .. 5 ] );
    return sprintf( '%4d-%02d-%02d %d:%02d:%02d', ( $year + 1900 ), ( $month + 1 ), @time_bits );
}

sub canonical_date_time ( $this_time = scalar( localtime() ) ) {
    return time2str( '%Y-%m-%d %X', str2time($this_time) || time );
}

sub zulu_date_time ( $this_time = scalar( localtime() ) ) {
    my %time;
    @time{ qw(
        year month day hour minute second
    ) } = reverse( ( localtime( str2time($this_time) ) )[ 0 .. 5 ] );
    $time{year} += 1900;
    $time{month}++;

    my $time_zone = 'Etc/UTC';
    try {
        $time_zone = DateTime::TimeZone->new( name => 'local' )->name;
    };

    my $dt = DateTime->new(
        %time,
        time_zone => $time_zone,
    );
    $dt->set_time_zone('Etc/UTC');

    return $dt->stringify() . 'Z';
}

1;

=head1 NAME

CBQZ::Util::Format

=head1 SYNOPSIS

    use exact;
    use CBQZ::Util::Format qw( log_date );

    say log_date();
    say log_date(time);

=head1 DESCRIPTION

This class offers a method for optional export that is related to formatting.
Nothing is exported by default.

=head1 METHODS

=head2 log_date

Given a timestamp (or if no timestamp is proviced, assumes now), this function
will return a string format of the timestamp suitable for logging headers.

    say log_date();
    say log_date(time);
