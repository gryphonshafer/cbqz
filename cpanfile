requires 'Modern::Perl', '>= 1.20150127';
requires 'Config::App', '>= 1.04';
requires 'Util::CommandLine', '>= 1.02';

requires 'Mojolicious', '>= 7.10';

requires 'Bible::OBML', '>= 1.06';

requires 'Moose';
requires 'MooseX::ClassAttribute';

requires 'Try::Tiny';
requires 'Log::Dispatch';
requires 'Term::ANSIColor';
requires 'Carp';
requires 'Exporter';
requires 'File::Path';
requires 'Mail::Send';

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
    requires 'Test::Moose';
    requires 'Devel::Cover';
};
