requires 'Modern::Perl', '>= 1.2';
requires 'Config::App', '>= 1.03';
requires 'Util::CommandLine';

requires 'Mojolicious', '>= 4.27';

# requires 'Date::Parse';
# requires 'IO::Dir', '>= 1';
# requires 'IO::File';
# requires 'IO::Uncompress::Unzip', '>= 2';
# requires 'LWP::UserAgent';
# requires 'LWP::Protocol::https';
# requires 'String::Diff';
# requires 'Text::CSV_XS', '>= 1.24';
# requires 'Time::Piece';
# requires 'YAML::XS';
# requires 'JSON::XS';
# requires 'DBIx::Query';

# requires 'Moose';
# requires 'MooseX::MarkAsMethods', '>= 0.13';
# requires 'MooseX::NonMoose', '>= 0.16';
# requires 'MooseX::ClassAttribute';

# requires 'Test::Moose';

# requires 'Mojolicious::Plugin::AccessLog';
# requires 'Mojolicious::Plugin::ToolkitRenderer', '>= 1.01';
# requires 'MojoX::Log::Dispatch::Simple';
# requires 'Template', '>= 2.25';
# requires 'Input::Validator';

# requires 'Mail::Sender';
# requires 'Net::IMAP::Simple';
# requires 'Email::Simple';
# requires 'MIME::Lite::TT';
# requires 'App::Dest', '>= 1.14';

on 'develop' => sub {
    requires 'Data::Dumper';
    requires 'Data::Printer';
    requires 'Perl::Critic';
    requires 'Perl::Tidy';
    requires 'Term::ReadKey';
    requires 'Term::ReadLine::Perl';
    requires 'Benchmark';
};

feature 'test', 'Testing Tools' => sub {
    requires 'Test::Most';

    # requires 'Test::CheckManifest';
    # requires 'Test::EOL';
    # requires 'Test::Kwalitee';
    # requires 'Test::NoTabs';
    # requires 'Test::Pod';
    # requires 'Test::Pod::Coverage';
    # requires 'Test::Synopsis';

    # requires 'Devel::Cover::Report::Coveralls';
    # requires 'Pod::Coverage::TrustPod';

    # requires 'Devel::Cover';
    # requires 'Parallel::Iterator';
    # requires 'Pod::Coverage';
    # requires 'Pod::Coverage::CountParents';
    # requires 'PPI::HTML';
    # requires 'Template';
};
