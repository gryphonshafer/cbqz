requires 'exact';
requires 'Config::App', '>= 1.04';

requires 'Moose';
requires 'MooseX::ClassAttribute';
requires 'MooseX::MarkAsMethods';
requires 'MooseX::NonMoose';

requires 'Mojolicious', '>= 7.10';
requires 'Mojolicious::Plugin::AccessLog';
requires 'Mojolicious::Plugin::ToolkitRenderer', '>= 1.01';
requires 'Mojolicious::Plugin::RequestBase';
requires 'MojoX::Log::Dispatch::Simple';

requires 'Carp';
requires 'Data::Printer';
requires 'DBD::mysql';
requires 'DBIx::Class';
requires 'DBIx::Query';
requires 'Digest::SHA';
requires 'Email::Mailer';
requires 'Exporter';
requires 'File::Path';
requires 'IO::All';
requires 'Log::Dispatch';
requires 'Log::Dispatch::Email::Mailer';
requires 'MIME::Base64';
requires 'Term::ANSIColor';
requires 'Time::Out';
requires 'Try::Tiny';

feature 'db', 'Deployment' => sub {
    requires 'DBIx::Class::Schema::Loader';
};

feature 't', 'Testing' => sub {
    requires 'Test::Most';
    requires 'Test::Moose';
    requires 'Test::MockModule';
};

feature 'tools', 'Tools and Etc.' => sub {
    requires 'Data::Printer';
    requires 'Encode';
    requires 'Parse::RecDescent';
    requires 'Term::ReadKey';
    requires 'Text::CSV_XS';
    requires 'Text::Unidecode';
    requires 'Util::CommandLine';
};

feature 'deploy', 'Deployment' => sub {
    requires 'App::Dest', '>= 1.17';
};
