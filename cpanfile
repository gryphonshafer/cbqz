requires 'Carp', '1.50';
requires 'Config::App', '1.13';
requires 'DBD::mysql', '4.050';
requires 'DBIx::Class', '0.082842';
requires 'DBIx::Query', '1.12';
requires 'Data::Printer', '0.40';
requires 'Date::Format', '2.24';
requires 'Date::Parse', '2.33';
requires 'DateTime', '1.54';
requires 'DateTime::TimeZone', '2.47';
requires 'Digest::SHA', '6.02';
requires 'Email::Mailer', '1.17';
requires 'Exporter', '5.74';
requires 'File::Path', '2.18';
requires 'IO::All', '0.87';
requires 'Log::Dispatch', '2.70';
requires 'Log::Dispatch::Email::Mailer', '1.11';
requires 'MIME::Base64', '3.16';
requires 'MojoX::Log::Dispatch::Simple', '1.08';
requires 'Mojolicious', '9.01';
requires 'Mojolicious::Plugin::AccessLog', '0.010001';
requires 'Mojolicious::Plugin::RequestBase', '0.3';
requires 'Mojolicious::Plugin::ToolkitRenderer', '1.10';
requires 'Moose', '2.2014';
requires 'MooseX::ClassAttribute', '0.29';
requires 'MooseX::MarkAsMethods', '0.15';
requires 'MooseX::NonMoose', '0.26';
requires 'Progress::Any', '0.219';
requires 'Progress::Any::Output', '0.219';
requires 'Term::ANSIColor', '5.01';
requires 'Text::CSV_XS', '1.45';
requires 'Text::Unidecode', '1.30';
requires 'Time::Out', '0.11';
requires 'exact', '1.17';

feature 'db', 'Deployment' => sub {
    requires 'DBIx::Class::Schema::Loader', '0.07049';
};

feature 'deploy', 'Deployment' => sub {
    requires 'App::Dest', '1.30';
};

feature 't', 'Testing' => sub {
    requires 'Test::MockModule', 'v0.176.0';
    requires 'Test::Moose', '2.2014';
    requires 'Test::Most', '0.37';
};

feature 'tools', 'Tools and Etc.' => sub {
    requires 'Data::Printer', '0.40';
    requires 'Encode', '3.08';
    requires 'IO::Socket::SSL', '2.069';
    requires 'Parse::RecDescent', '1.967015';
    requires 'Progress::Any::Output::TermProgressBarColor', '0.249';
    requires 'Term::ReadKey', '2.38';
    requires 'Util::CommandLine', '1.06';
};
