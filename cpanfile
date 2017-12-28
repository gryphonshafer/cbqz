requires 'exact';
requires 'Config::App', '>= 1.04';

requires 'Moose';
requires 'MooseX::ClassAttribute';

requires 'Mojolicious', '>= 7.10';
requires 'Mojolicious::Plugin::AccessLog';
requires 'Mojolicious::Plugin::ToolkitRenderer', '>= 1.01';
requires 'Mojolicious::Plugin::RequestBase';
requires 'MojoX::Log::Dispatch::Simple';

requires 'Carp';
requires 'DBD::mysql';
requires 'DBIx::Class';
requires 'DBIx::Query';
requires 'Digest::SHA';
requires 'Email::Mailer';
requires 'Exporter';
requires 'File::Path';
requires 'MIME::Base64';
requires 'IO::All';
requires 'Log::Dispatch';
requires 'Log::Dispatch::Email::Mailer';
requires 'Term::ANSIColor';
requires 'Term::ReadKey';
requires 'Time::Out';
requires 'Try::Tiny';

feature 'test', 'Testing' => sub {
    requires 'Test::Most';
    requires 'Test::Moose';
    requires 'Test::MockModule';
};

feature 'tools', 'Tools and Etc.' => sub {
    requires 'Data::Printer';
    requires 'Parse::RecDescent';
    requires 'Util::CommandLine';
    requires 'Text::CSV_XS';
    requires 'Encode';
    requires 'Text::Unidecode';
};

feature 'deploy', 'Deployment' => sub {
    requires 'App::Dest', '>= 1.17';
};

feature 'db', 'Deployment' => sub {
    requires 'DBIx::Class::Schema::Loader';
    requires 'MooseX::MarkAsMethods';
    requires 'MooseX::NonMoose';
};
