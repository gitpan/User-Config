package User::Config::DB;

use strict;
use warnings;
use Moose::Role;

our $VERSION = '0.01_01';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

requires 'get';
requires 'set';

=pod

=head1 NAME

User::Config::DB - This defines the role, the database-backends are playing.

=head1 DESCRIPTION

To store the value, a user set for a given option, L<User::Config> uses a
database-backend. These backends must live within the namespace
User::Config::DB:: and consume this role.

=head2 CONSUMER-METHODS

The interface was held as simple as possible. To consume this role, the
following methods have to be implemented.

=head3 C<<$db->set($package, $user, $option_name, $context, $value)>>

The C<set> method has to be implemented. Whenever a user sets a speicific
option to a new value, this method is called and has to take care of storing
this piece of information.

The parameters are as following:

=over 4

=item C<$package>

Contains the package or namespace for the module in question. This usally is
the package-name of the module, declaring the option.

=item C<$user>

The name of the current contexts user.

=item C<$option_name>

The name of the option to set ( within the package ).

=item C<$context>

The current context.

=item C<$value>

The new value to set.

=back

=head3 C<<$db->get($package, $user, $option_name, $context)>>

The C<get> method has to be implemented by the corresponding backend. It
returns the previous set value or undef, if no value was set.

The parameters work are the same as for C<set>.

=head3 C<<$db->isset($package, $user, $option_name, $context)>>

Optionally, the backend can implement the C<isset>-method. This will be called
before C<get> is called. If the user has set this option in advance, the method
should return true. If not, false should be returned. Then C<get> isn't called at
all and the default value will be submitted to the caller.

The parameters work are the same as for C<set>.

If this isn't implemented C<get> is always called. The default value will then
be returned, if C<get> returns undef.

=head2 INTERNALS

The following information aren't needed to write new code. There here for
completness only.

While C<set> is just checking, wether the user is valid, C<get> is completly
wrapped in this role. The wrapper checks wether the backend implements C<isset>
and returns the user-set value or the default, if the setting isn't stored.

=cut

around set => sub {
	my $code = shift;
	my ($self, $namespace, $user, $name, $ctx, $value) = @_;
	my $opts = User::Config::instance()->options()->{$namespace}->{$name};
	return if $opts->{noset};
	return unless $user;
	return &$code(@_);
};

around get => sub {
	my $code = shift;
	my $self = shift;
	my ($namespace, $user, $name, $ctx) = @_;

	return $self->default(@_) unless $user;
	if($self->can("isset")) {
		return &$code($self, @_)
			if $self->isset(@_);
		return $self->default(@_);
	}
	my $ret = &$code( $self, @_);
	return $ret if defined $ret;
	return $self->default(@_);
};

=pod

The default value is given while the option is declared. If the default value
is a code-reference, the code is called. The returned value is immediatly
saved in the backend, so that it get's returned the next time the option is
retrieved.

=cut

sub default {
	my ($self, $namespace, $user, $name, $ctx) = @_;
	my $def;
	my $opts = User::Config::instance()->options()->{$namespace}->{$name};
	$def = $opts->{anon_default} unless $user;
	$def = $opts->{default} unless $def;
	return unless $def;
	return $def unless ref $def;
	if(ref $def eq "CODE") {
		my $ret = &$def($ctx, $name);
		$self->set($namespace, $user, $name, $ctx, $ret);
		return $ret;
	}
	return $def;
}


=head1 SEE ALSO

L<User::Config>
L<User::Config::DB::DBIC>
L<User::Config::DB::Ldap>
L<User::Config::DB::Keyed>

Further backends are welcome.

=head1 AUTHOR

Benjamin Tietz E<lt>benjamin@micronet24.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Benjamin Tietz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

