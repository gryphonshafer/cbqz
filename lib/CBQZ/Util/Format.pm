package CBQZ::Util::Format;

use Modern::Perl '2015';

require Exporter;

our @ISA       = 'Exporter';
our @EXPORT_OK = qw(
    log_date html_to_text
);

{
    my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    sub log_date {
        my ($this_time) = @_;
        $this_time ||= time;

        my ( $year, $month, @time_bits ) = reverse( ( localtime($this_time) )[ 0 .. 5 ] );
        return sprintf( '%3s %2d %2d:%02d:%02d %4d', $abbr[$month], @time_bits, ( $year + 1900 ) );
    }
}

1;
