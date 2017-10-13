#!/usr/bin/env perl
use exact;
use Config::App;
use DBIx::Class::Schema::Loader 'make_schema_at';
use Util::CommandLine 'podhelp';

my ( $dsn, $dbname, $username, $password ) =
    @{ Config::App->new->get('database') }{ qw( dsn dbname username password ) };

make_schema_at(
    'CBQZ::Db::Schema',
    {
        overwrite_modifications => 0,

        dump_directory     => "$FindBin::Bin/../lib",
        naming             => 'current',
        quiet              => 0,
        generate_pod       => 1,
        use_namespaces     => 1,
        use_moose          => 1,
        skip_load_external => 1,
        schema_base_class  => 'CBQZ::Db',
        result_roles_map   => {
            User => ['CBQZ::Db::Base::Result::User'],
        },
    },
    [ $dsn . $dbname, $username, $password ],
);

=head1 NAME

schema_loader.pl - Automatically Build DBIx::Class Schema Files

=head1 SYNOPSIS

    schema_loader.pl

=head1 DESCRIPTION

This program automatically builds the DBIx::Class schema files based on the
current state of the database. It does so by reverse-engineering the database.
This includes table definitions and relationships.

In addition, it will setup a schema base class of CBQZ::Db to allow
for any needed overriding without having to edit the automatically generated
files. See also the roles within CBQZ::Db::Base::Result which are there
for the same reason.

It ought to be completely safe to run this file at any time. It must be run
after any database schema change to keep the DBIx::Class schema files in sync
with the database.
