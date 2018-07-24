requires 'exact', '>= 1.05';
requires 'Config::App', '>= 1.06';

requires 'Moose', '>= 2.2011';
requires 'MooseX::ClassAttribute', '>= 0.29';
requires 'MooseX::MarkAsMethods', '>= 0.15';
requires 'MooseX::NonMoose', '>= 0.26';

requires 'Mojolicious', '>= 7.85';
requires 'Mojolicious::Plugin::AccessLog', '>= 0.010';
requires 'Mojolicious::Plugin::ToolkitRenderer', '>= 1.08';
requires 'Mojolicious::Plugin::RequestBase', '>= 0.3';
requires 'MojoX::Log::Dispatch::Simple', '>= 1.05';

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
requires 'Progress::Any';
requires 'Progress::Any::Output';
requires 'Term::ANSIColor';
requires 'Text::CSV_XS';
requires 'Text::Unidecode';
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
    requires 'Util::CommandLine';
};

feature 'deploy', 'Deployment' => sub {
    requires 'App::Dest', '>= 1.18';
};
