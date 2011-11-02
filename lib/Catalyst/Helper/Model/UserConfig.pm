package Catalyst::Helper::Model::UserConfig;

use strict;
use warnings;

our $VERSION = '0.01_00';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

=pod

=head1 NAME

Catalyst::Helper::Model::UserConfig - Helper Class to generate L<Catalyst>
Models intefacing L<User::Config>

=head1 SYNOPSIS

  myapp_create.pl Model Configuration UserConfig [DB_Type] [DB_Args]

=head1 DESCRIPTION

This will create a new model-class within a catalyst app. DB_Type may be
replaced one of the L<User::Config::DB>. DB_Args depend on them. currently
supported are the following types

=over 4

=item Mem

This will use the default memory backed database interface. This doesn't support
any arguments.

=item DBIC

This will use DBIx::Class for the storage of the values.
The db-args will be the connection-string needed to connect to the database.

  myapp_create.pl Model Configuration UserConfig DBIC dbi:SQlite:database.db MyApp::Schema MyResulSet

The order for the arguments is the database-string, the schema-class and the resultset.
See L<User::Config::DB::DBIC>

=item Keyed

This will use a table in a given database for storing all values in a single
keyed table. The synopsis would be eg.

  myapp_create.pl Model Configuration UserConfig Keyed dbi:SQlite:database.db tablename

See L<User::Config::DB::Keyed>

=item Ldap

This will use L<User::Config::DB::Ldap> as store. If only one arg is given,
this will be interpreted as code to retrieve a bound Net::Ldap object.
Otherwise four parameters are needed as following:

  myapp_create.pl Model Configuration UserConfig Ldap host rootdn binddn bindpwd

=back

In all cases the default parameter counting can be omitted by inserting '--' and
adding explicit pairs of keys and values as used in the initializer.

=head2 METHODS

=head3 mk_compclass

generates the class

=cut

my %_parse_args = (
	Keyed => [qw/db table/],
	DBIC => [qw/db schema resultset/],
	Ldap => [qw/host rootdn binddn* bindpwd*/],
);

sub _parse_args {
	my ($set, $names, $arr) = @_;
	for(@{$names}) {
		my $opt;
		if(m/\*$/) { $opt = 1; chop };
		my $nam = $_;
		my $val = shift(@{$arr});
		unless(defined $val) {
			warn "value for $nam is undefined" unless $opt;
			return;
		}
		return if $val eq "--";
		$set->{$nam} = $val;
	}
}

sub mk_compclass {
	my ($self, $helper, $db_type, @db_args ) = @_;

	$helper->{type} = $db_type;
	$helper->{settings} = {};
	_parse_args($helper->{settings}, $_parse_args{$db_type}, \@db_args)
		if $db_type and $_parse_args{$db_type};
	$helper->render_file('modelclass', $helper->{file});

	return 1;
}

=head3 mk_comptest

generates tests for the new class

=cut

sub mk_comptest {
	my ($self, $helper) = @_;

	$helper->render_file('modeltest', $helper->{test});
}

=head1 SEE ALSO

L<Catalyst>

L<User::Config>

L<User::Config::Manual>

=head1 AUTHOR

Benjamin Tietz E<lt>benjamin@micronet24.deE<gt>

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__DATA__

=begin pod_to_ignore

__modelclass__
package [% class %];

use strict;
use warnings;
use base "Catalyst::Model::Adaptor";
use User::Config;
use User::Config::UI::HTMLFormHandler;
use namespace::autoclean;

__PACKAGE__->config(
	class => "User::Config",
	constructor => "instance",
);

[% IF type %]User::Config->instance->db('[% type %]', {
[% FOREACH val IN settings.keys.sort %]
	[% val %] => "[% settings.$val %]",
[% END %]
});
[% END %]

=head1 NAME

[% class %] - Accessing user configuration values

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

See L<User::Config>

Additional a convenient helper to L<User::Config::UI::HTMLFormHandler> can be
used. This can be used using

  $c->model('UserConfig')->form()

C<form> accepts the same parameters as User::Config::UI::HTMLFormHandler->new.

=cut

sub form {
	my $self = shift;
	return $self->ui("HTMLFormHandler", @_);
}

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
__modeltest__
use strict;
use warnings;
use Test::More tests => 2;

use_ok('Catalyst::Test', '[% app %]');
use_ok('[% class %]');

