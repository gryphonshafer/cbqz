package CBQZ::Model::Email;

use Moose;
use MooseX::ClassAttribute;
use exact;
use Email::Mailer;
use Template;
use CBQZ::Util::Template 'tt_settings';
use CBQZ;

extends 'CBQZ::Model';

class_has 'settings' => ( isa => 'HashRef', is => 'ro', lazy => 1, default => sub ($self) {
    return tt_settings(
        'email',
        $self->config->get('template'),
        { version => $self->config->get('version') },
    );
} );

class_has 'tt' => ( isa => 'Template', is => 'ro', lazy => 1, default => sub ($self) {
    my $tt = Template->new( $self->settings->{config} );
    $self->settings->{context}->( $tt->context );
    return $tt;
} );

class_has 'mailer' => ( isa => 'Email::Mailer', is => 'ro', lazy => 1, default => sub ($self) {
    return Email::Mailer->new(
        from    => $self->config->get( qw( email from ) ),
        process => sub {
            my ( $template, $data ) = @_;
            my $content;
            $self->tt->process( \$template, $data, \$content );
            return $content;
        },
    );
} );

class_has 'active' => ( isa => 'Bool', is => 'ro', lazy => 1, default => sub ($self) {
    return $self->config->get( qw( email active ) );
} );

has subject => ( isa => 'Str', is => 'rw' );
has html    => ( isa => 'Str', is => 'rw' );
has type    => ( isa => 'Str', is => 'rw', trigger => sub {
    my ( $self, $type ) = @_;
    return unless ($type);

    my ($file) =
        grep { -f $_ }
        map { $_ . '/' . $type . '.html.tt' }
        @{ $self->settings->{config}{INCLUDE_PATH} };
    E->throw("Failed to find email template of type: $type") unless ($file);

    open( my $html, '<', $file ) or E->throw("Unable to open email template: $file");
    $html = join( '', <$html> );
    my $subject = ( $html =~ s|<title>(.*?)</title>||ms ) ? $1 : '';
    $subject =~ s/\s+/ /msg;
    $subject =~ s/(^\s|\s$)//msg;

    $self->subject($subject);
    $self->html($html);
} );

sub send ( $self, $data ) {
    $data->{subject} = \$self->subject;
    $data->{html}    = \$self->html;

    return ( $self->active ) ? $self->mailer->send($data) : undef;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

CBQZ::Model::Email

=head1 SYNOPSIS

    use CBQZ::Model::Email;

    my $email = CBQZ::Model::Email->new( type => 'new_user_registration' );

    $email->send({
        to   => 'admin@example.com',
        data => {
            name    => 'Example',
            email   => 'user@example.com',
            program => 'Bible Quizzing',
        },
    });
