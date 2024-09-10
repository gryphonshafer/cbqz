requires 'Carp', '1.50';
requires 'Config::App', '1.17';
requires 'DBD::MariaDB', '1.23';
requires 'DBIx::Class', '0.082843';
requires 'DBIx::Class::Storage::DBI::MariaDB', 'v0.1.0';
requires 'DBIx::Query', '1.15';
requires 'Data::Printer', '1.002001';
requires 'Date::Format', '2.24';
requires 'Date::Parse', '2.33';
requires 'DateTime', '1.65';
requires 'DateTime::TimeZone', '2.63';
requires 'Digest::SHA', '6.04';
requires 'Email::Mailer', '1.19';
requires 'Exporter', '5.78';
requires 'File::Path', '2.18';
requires 'IO::All', '0.87';
requires 'Log::Dispatch', '2.71';
requires 'Log::Dispatch::Email::Mailer', '1.13';
requires 'MIME::Base64', '3.16';
requires 'MojoX::Log::Dispatch::Simple', '1.12';
requires 'Mojolicious', '9.38';
requires 'Mojolicious::Plugin::AccessLog', '0.010001';
requires 'Mojolicious::Plugin::RequestBase', '0.3';
requires 'Mojolicious::Plugin::ToolkitRenderer', '1.12';
requires 'Moose', '2.2207';
requires 'MooseX::ClassAttribute', '0.29';
requires 'MooseX::MarkAsMethods', '0.15';
requires 'MooseX::NonMoose', '0.26';
requires 'Progress::Any', '0.220';
requires 'Progress::Any::Output', '0.220';
requires 'Term::ANSIColor', '5.01';
requires 'Text::CSV_XS', '1.56';
requires 'Text::Unidecode', '1.30';
requires 'Time::Out', '0.24';
requires 'exact', '1.26';

feature 'db', 'Deployment' => sub {
    requires 'DBIx::Class::Schema::Loader', '0.07052';
};

feature 'deploy', 'Deployment' => sub {
    requires 'App::Dest', '1.33';
};

feature 't', 'Testing' => sub {
    requires 'Test::MockModule', 'v0.176.0';
    requires 'Test::Moose', '2.2207';
    requires 'Test::Most', '0.38';
};

feature 'tools', 'Tools and Etc.' => sub {
    requires 'Data::Printer', '1.002001';
    requires 'Encode', '3.21';
    requires 'IO::Socket::SSL', '2.089';
    requires 'Parse::RecDescent', '1.967015';
    requires 'Progress::Any::Output::TermProgressBarColor', '0.249';
    requires 'Term::ReadKey', '2.38';
    requires 'Util::CommandLine', '1.07';
};
