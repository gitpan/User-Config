package User::Config::DB::Mem;

use strict;
use warnings;

use Moose;
with 'User::Config::DB';

our $VERSION = '0.01_00';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

=pod

=head1 NAME

User::Config::DB::Mem - Storing the user-configuration in memory, only.

=head1 DESCRIPTION

This is a database-backend for L<User::Config>. All options will be stored
in RAM and be lost after the nect restart of the application. But as it will run
without configuration, it is the default backend.

=head2 METHODS

=head3 C<isset()>, C<set()> and C<get()>

See L<User::Config::DB>

=head2 SEE ALSO

=over 4

=item L<User::Config::DB::Ldap> 

Stores the configuration data on an LDAP-Server

=item L<User::Config::DB::Keyed>

Stores the configuration data in an relational database-table

=item L<User::Config::DB::DBIC>

uses an DBIx::Class Schema to store the configuration-data.

=back

=cut

sub set {
	my ($self, $namespace, $user, $name, $ctx, $value) = @_;

	$self->{$namespace}->{$user}->{$name} = $value;
}

sub isset {
	my ($self, $namespace, $user, $name, $ctx) = @_;
	return unless $self->{$namespace};
	return unless $self->{$namespace}->{$user};
	return exists $self->{$namespace}->{$user}->{$name};
}

sub get {
	my ($self, $namespace, $user, $name) = @_;
	return $self->{$namespace}->{$user}->{$name};
}

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

