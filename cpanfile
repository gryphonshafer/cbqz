requires 'exact', '>= 1.05';
requires 'Config::App', '>= 1.08';

requires 'Moose', '>= 2.2011';
requires 'MooseX::ClassAttribute', '>= 0.29';
requires 'MooseX::MarkAsMethods', '>= 0.15';
requires 'MooseX::NonMoose', '>= 0.26';

requires 'Mojolicious', '>= 7.92';
requires 'Mojolicious::Plugin::AccessLog', '>= 0.010';
requires 'Mojolicious::Plugin::ToolkitRenderer', '>= 1.08';
requires 'Mojolicious::Plugin::RequestBase', '>= 0.3';
requires 'MojoX::Log::Dispatch::Simple', '>= 1.05';

requires 'Carp', '>= 1.38';
requires 'Data::Printer', '>= 0.40';
requires 'Date::Format', '>= 2.24';
requires 'Date::Parse', '>= 2.30';
requires 'DBD::mysql', '>= 4.046';
requires 'DBIx::Class', '>= 0.082841';
requires 'DBIx::Query', '>= 1.06';
requires 'Digest::SHA', '>= 6.02';
requires 'Email::Mailer', '>= 1.08';
requires 'Exporter', '>= 5.72';
requires 'File::Path', '>= 2.15';
requires 'IO::All', '>= 0.87';
requires 'Log::Dispatch', '>= 2.67';
requires 'Log::Dispatch::Email::Mailer', '>= 1.03';
requires 'MIME::Base64', '>= 3.15';
requires 'Progress::Any', '>= 0.214';
requires 'Progress::Any::Output', '>= 0.214';
requires 'Term::ANSIColor', '>= 4.06';
requires 'Text::CSV_XS', '>= 1.36';
requires 'Text::Unidecode', '>= 1.30';
requires 'Time::Out', '>= 0.11';
requires 'Try::Tiny', '>= 0.30';

feature 'db', 'Deployment' => sub {
    requires 'DBIx::Class::Schema::Loader', '>= 0.07049';
};

feature 't', 'Testing' => sub {
    requires 'Test::Most', '>= 0.35';
    requires 'Test::Moose', '>= 2.2011';
    requires 'Test::MockModule', '>= 0.170';
};

feature 'tools', 'Tools and Etc.' => sub {
    requires 'Data::Printer', '>= 0.40';
    requires 'Encode', '>= 2.98';
    requires 'Parse::RecDescent', '>= 1.967015';
    requires 'Term::ReadKey', '>= 2.37';
    requires 'Util::CommandLine', '>= 1.03';
};

feature 'deploy', 'Deployment' => sub {
    requires 'App::Dest', '>= 1.20';
};
