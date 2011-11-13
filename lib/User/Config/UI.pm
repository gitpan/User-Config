package User::Config::UI;

use strict;
use warnings;

use Moose::Role;
require User::Config;

our $VERSION = '0.01_00';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

=pod

=head1 NAME

User::Config::UI - some helper-functions for User::Config UI-Generators

=head1 DESCRIPTION

Within the User::Config::UI namespace the UI-Generators for L<User::Config>
reside. Additionaly this modul will provide some common functions for these.

=head1 SEE ALSO

L<User::Config>

=head2 Known UI-Generators

L<User::Config::UI::HTMLFormHandler> - uses L<HTML::FormHandler> to process
and generate a HTML-Form

=head1 EXPORT

=head2 User::Config::UI::get_options

This will a hashref of hashes containing all options in all known modules.

The tree of the module-namespace is mapped on the references. Hashes with
option will contain an additional key called C<is_option>.

  package Module;
  ...
  has_option option1;
  ...
  package Module::SubModule;
  ...
  has_option option2;
  ...
  use Data::Dumper;
  use User::Config::UI;
  print Dumper User::Config::UI::get_options

will generate the following 

  VAR1 => {
  	Module => {
		option1 => {
			is_option => 1
		},
		SubModule => {
			option2 => {
				is_option => 1
			}
		}
	}
  }

It is recommended for UI-Generators to use this function to generate their
list of options.

=cut

sub _split_opts {
	my ($ret, $name) = @_;
	my @name = split /::/,$name;
	for(@name) {
		$ret->{$_} = {} unless $ret->{$_};
		$ret = $ret->{$_};
	}
	return $ret;
}

sub get_options {
	my $self = shift;
	my $ret = {};

	my $uc = User::Config->instance;
	my $opts = $uc->options;
	for(keys %{$opts}) {
		my $name = $_;
		next unless $name =~ $self->modulefilter;
		my $kopt = _split_opts($ret, $name);
		my $nso = $opts->{$name};
		map {
			$kopt->{$_} = $opts->{$name}->{$_};
			$kopt->{$_}->{is_option} => 1
		} grep {
			$nso->{$_} and not 
			($nso->{$_}->{hidden} or
			 $nso->{$_}->{noset} or
			 $nso->{$_}->{references})
		} keys %{$nso};
	}
	return $ret;
}

=head2 ATTRIBUTES

=head3 modulefilter

If given in the initialization of an UI-object, this will specifiy a
regular expression, all modules to configure must match.

By default all options in all modules will be shown.

=cut

has modulefilter => (
	is => "ro",
	isa => "RegexpRef",
	default => sub { qr/./ },
);

=head1 AUTHOR

Benjamin Tietz E<lt>benjamin@micronet24.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Benjamin Tietz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

