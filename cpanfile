requires 'exact';
requires 'Config::App', '>= 1.04';

requires 'Moose';
requires 'MooseX::ClassAttribute';
requires 'Mojolicious', '>= 7.10';

requires 'Carp';
requires 'Email::Mailer';
requires 'Exporter';
requires 'File::Path';
requires 'IO::All';
requires 'Log::Dispatch';
requires 'Log::Dispatch::Email::Mailer';
requires 'Term::ANSIColor';
requires 'Try::Tiny';

feature 'test', 'Testing' => sub {
    requires 'Test::Most';
    requires 'Test::Moose';
};

feature 'tools', 'Tools' => sub {
    requires 'Data::Printer';
    requires 'Parse::RecDescent';
    requires 'Util::CommandLine';
};
