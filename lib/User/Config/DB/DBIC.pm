package User::Config::DB::DBIC;

use strict;
use warnings;

use Moose;
with 'User::Config::DB';
use DBI;

our $VERSION = '0.01_00';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

=pod

=head1 NAME

User::Config::DB::DBIC - Use an DBIx::Class schema to store the user-configuration
data.

=head1 SYNOPSIS

  use User::Config;

  my $uc = User::Config->instance;
  $uc->db("DBIC",  {
  	schema => "My::DBIC::Schema",
  	db => "dbi:SQLite:user.sqlite",
  	resultset => "Configuration",
  });

This assumes you want the resultset 
C<My::DBIX::Schema::ResultSet::Confiuration> to store your options.

=head1 DESCRIPTION

This is a database-backend for L<User::Config>. How the options get stored in which table
will be defined using a L<DBIx::Class> schema and some optional helper-routines.

=head2 ATTRIBUTES

All attributes are read-only and should be given at the time of initialization.

=head3 db

This attribute contains a L<DBI>-string to connect to the database.
Its presence is mandatory.

=cut

has db => (
	is => "ro",
	isa => "Str",
	required => 1,
);

=head3 schema

This contains the name of the schema used to interact with the database.
Mandatory.

=cut

has schema => (
	is => "ro",
       	required => 1,
);

=head3 resultset

The name of the resultset within the schema to use.
Mandatory.

=cut

has resultset => (
	is => "ro",
       	isa => "Str",
       	required => 1,
);

=head3 usercol

The name of the primary key to use for filtering for a certain user.
Optional. Default: "uid"

=cut

has usercol => (
	is => "ro",
       	isa => "Str",
       	default => "uid",
);

=head3 db_user and db_pwd

These optional attributes will contain the username and password needed to
connect to the database.

=cut

has [ qw/db_user db_pwd/ ] => is => "ro", default => undef;

=head2 METHODS

=for comment
BUILD will connect the schema and prepare the handle for further interaction

=cut

sub BUILD {
	my ($self) = @_;

	my $cls = $self->schema;
	my $schema = eval "require $cls; $cls"."->connect(".
		"'".$self->db."', ".
		(defined($self->db_user)?"'".$self->db_user."',":"undef,").
		(defined($self->db_pwd)?"'".$self->db_pwd."',":"undef,").
		"{ AutoCommit => 1 })";
	die $@ if $@;
	$self->{schema} = $schema->resultset($self->resultset);
}

sub _get_rs {
	my ($self, $namespace, $user, $name) = @_;
	my $col = $namespace."::".$name;
	$col =~ s/::/_/g;
	my $rs = $self->{schema}->search(
		       	{ $self->usercol => $user },
			{ columns => [ $col ] }
	       	);
	return ($rs, $col);
}

=head3 C<$db->set($package, $user, $option_name, $context, $value)>

assigns the value for the given user to the option within a package.
See L<User::Config::DB>

=cut

sub set {
	my ($self, $namespace, $user, $name, $ctx, $value) = @_;
	my ($rs, $col) = $self->_get_rs($namespace, $user, $name);
	if($rs == 0) {
		return $rs->create({$col => $value});
	} else {
		return $rs->update({$col => $value});
	}
}

=head3 C<$db->get($package, $user, $option_name, $context)>

returns the set value.
See L<User::Config::DB>

=cut

sub get {
	my $self = shift;
	my ( $rs, $col ) = $self->_get_rs(@_);
	return $rs->get_column($col)->first();
}

=head1 SEE ALSO

L<User::Config>
L<DBIx::Class>
L<User::Config::DB>

=head1 AUTHOR

Benjamin Tietz E<lt>benjamin@micronet24.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Benjamin Tietz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
1;

