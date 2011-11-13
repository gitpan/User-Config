package User::Config;

use 5.010001;
use strict;
use warnings;

use Moose;
use Moose::Exporter;
use Carp;
use User::Config::DB::Mem;

our $VERSION = '0.02_01';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

#Moose::Exporter->setup_import_methods is called at the end of this document,
# to make sure all accessors are valid

=pod

=head1 NAME

User::Config - Handling the per-user configuration in multi-user applications

=head1 SYNOPSIS

  use User::Config;

  has_option foo => (
  	isa => 'String',
	documentation => 'a sample option',
	default => 'foobar',
	dataclass => 'myclass',
	presets => {
		"Use this" => "value",
		"or this" => "another value",
		custom => undef,
	},
  );

  has_option bar => (
  	isa => 'Integer',
	default => sub { return 28; },
	hidden => 1,
  );

  ...
  	$setting = $self->foo;
		
=head1 DESCRIPTION

This primaly documents this modules interface. Please see
L<User::Config::Manual> for an in-depth discussion of the concepts.

=cut

my $instance;

sub _context_test {
	my ($val) = @_;
	return 0 unless $val and ref $val;
	return 1 if exists $val->{user};
	return 1 if $val->can("user");
	return 0;
}

=head2 EXPORTS

=head3 has_option name;

C<has_option> is the way to declare new user-configurable options. To specify
the behaviour of this modul, the extended syntax with parameters can be used.
The following parameters are currently supported:

=over 4

=item C<<anon_default => ($default|sub { ... })>>

Will be used as C<default>, but only if no user logged in. If this isn't given, C<default> is used.

=item C<<coerce => (1|0)>>

Use coercion. See L<Moose/has>

=item C<<dataclass => $db_class>>

this entry might be used by the database-backend to decide how or where
to save the entry

=item C<<default => ($default|sub { ... })>>

defines the default value for a given entry. If defined this either might be
a scalar, which will be used as value for this option, as long as the user
didn't set it to something else. Or it might be a CODE-ref. In this case
the code will be executed the first time this option is read for a certain
user. On this first time it automaticly will be set in the backend.

=item C<<documentation => "Documentative string">>

Document the option. This will be accessable as $self->item->documentation and
may be used by UI-Generators.

=item C<<hidden => (1|0)>>

If this set to a true value, the corresponding item will be ignored by the
UI-Generator.

=item C<<isa => $type_name>>

set up runtime constrain checking for this option using L<Moose/has>.

=item C<<lazy => (1|0)>>

See L<Moose/has>

=item C<<noset => (1|0)>>

If set to something true, a value set to this value will silently be
ignored. This implies C<hidden>.
This might be useful in conjunction with C<default>/C<anon_default>, if
a database-connection night not be available.

=item C<<range => [ $min, $max ]>>

if this is set, the UI-Generator will assure, that the user didn't set
a value outside.

=item C<<references => 'Path::To::Modul::option_name'>>

this tells User::Config to access the C<option_name> of the Modul
C<Path::To::Modul>, when this option is accessed. Thus both options always
will have the same value. The UI-Generator will silently ignore this option
and do not a display a corresponding entry to the user.

=item C<<trigger => sub { ... }>>

triggers the following code every time the option is set. See L<Moose/has> for
details.

=item C<<ui_type => 'String'>>

this will be used by the UI-Generator to provide a suitable element.

=item C<<validate => CODEREF>>

a code that will be executed, if the user set's a new value.

=item C<<weak_ref => (1|0)>>

See L<Moose/has>

=back

=cut

sub has_option {
	my ($meta, $name, %options) = @_;

	my $call = Moose::Util::_caller_info();
	my $be = User::Config::instance();
	Moose->throw_error(
			'Usage: has_option \'name\' => ( key => value, ... )')
		if @_ % 2 == 1;
	$options{is_option} = 1;
	$be->options($call->{package}, $name, \%options);

	if($options{references}) {
		my @name = split(/::/,$options{references});
		my $module = join('::', @name[0..($#name-1)]);
		my $option = $name[-1];
		$meta->add_attribute($name => (
				accessor => { $name => sub {
					my $self = shift;
					return eval "$module->$option(\@_)";
				}},
				definition_context => $call,
				map { $_ => $options{$_} }
					grep { exists $options{$_} }
					qw/isa coerce weak_ref lazy trigger documentation/,
			));
		return;
	}

	$meta->add_attribute($name => (
		accessor => {
			$name => sub {
				my $self = shift;
				my $option = User::Config->instance;
				my ($context, $user);
				my $getter = defined wantarray;
				$context = shift
					if(($getter?($_[0]):(defined $_[1])) and
						_context_test($_[0]));
			       	$context = $self->context unless $context;
				$context = $option->context unless $context;
				if($context) {
					$user = $context->{user}
						if exists $context->{user};
					$user = $context->user
						if not defined $user and 
						ref $context ne "HASH" and 
						$context->can("user");
				}
				my $ns = blessed($self);
				$ns = $self unless $ns;
				if($getter) {
					return $option->db->get($ns,
						$user, $name, $context);
				} else {
					$option->db->set($ns,
						$user, $name, $context, shift);
				}
			}
		},
		definition_context => $call,
		map { $_ => $options{$_} }
			grep { exists $options{$_} }
			qw/isa coerce weak_ref lazy trigger documentation/,
	));
}

=head2 METHODS

=head3 $self->context({ User => 'foo' });

This can be used to set the global or module-wide context.
See L<User::Config::Manual> for more details.

=cut

has context => (
	is => 'rw',
	trigger => sub {
		my ($self, $new, $old) = @_;
		return unless defined $new;
		return if _context_test($new);
		# no user found; reset to old value
		$self->context($old);
	},
);

=head3 my $uc = User::Config->instance

C<instance> will always return a handle to the global over-all object handling
with the database-backend and storing references to all configuration
items

=cut

has instance => (
	reader => {
		instance => sub {
			$instance = User::Config->new unless $instance;
			return $instance;
		}
	}
);

=head3 $uc->db("Interface", { parameters => "" })

To set the database used to make any user-configuration persistent, the
database should be set using this method. The first argument specifies the
interface to be used, the second contains arguments for this interface to
initialize.

For a list of valid Interfaces see L<User::Config::DB>

=cut

has db => (
	default => sub { User::Config::DB::Mem->new },
	accessor => {
		db => sub {
			my ($self, $val, $arg ) = @_;

			# Sometimes the writer is called instead of the reader?
			return $self->{db} unless $val;
			my $mod = "User::Config::DB::$val";
			my $ret = eval "require $mod; $mod->new(\$arg)";
			croak $@ if $@;
			$self->{db} = $ret;
			return $ret;
		}
	},
);


=head3 $uc->ui("Interface", { parmeters => "" })

This will return a new instance for generating a userinterface. There might be
multiple interfaces supported. To choose one of them, provide the name of the
Interface as first parameter. Valid names are any modules within
L<User::Config::UI>. The parameters to supply will depend on the interface in
use, so please refer to it's documentation.

=cut

sub ui {
	my ($self, $name, $params) = @_;

	my $mod = "User::Config::UI::$name";
	my $ret = eval "require $mod; $mod->new(\$params)";
	croak $@ if $@;
	return $ret;
}

=head3 $uc->options

This will return a hash-ref containing all currently registered options. The
content will look like the following example. The reference of a given 
option will be the same as used in C<has_option>.

  $ perl ... -e "print Dumper $uc->options"
  $VAR1 = {
  	My::Namespace => {
		option1 => {
		},
		option2 => {
			hidden => 1,
		},
	};

=cut

has options => (
	is => "rw",
	accessor => {
		options => sub {
			my $self = shift;
			$self->{options}->{$_[0]}->{$_[1]} = $_[2]
				if scalar @_ and (caller)[0] eq "User::Config";
			return $self->{options};

		},
	},
);

=head1 SEE ALSO

L<User::Config::Manual> - a introduction into the concept behind User::Config

L<User::Config::DB> - for a Overview over the database-backends

L<User::Config::UI> - for more information on generating User-Interfaces

=head1 AUTHOR

Benjamin Tietz, E<lt>benjamin@micronet24.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Benjamin Tietz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

Moose::Exporter->setup_import_methods(
	with_meta => [ qw/has_option/ ],
	as_is => [ qw/context/ ],
	also => 'Moose',
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
