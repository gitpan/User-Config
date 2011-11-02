package User::Config::UI::HTMLFormHandler::Model;

use strict;
use warnings;

use HTML::FormHandler::Model;

our $VERSION = '0.01_00';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

=pod

=head1 NAME

User::Config::UI::HTMLFormHandler::Model - a model for L<HTML::FormHandler>
interfacing the Form-entries with L<User::Config>.

=head1 SYNOPSIS

  package MyApp::Form;
  use HTML::FormHandler::Moose;
  extends User::Config::UI::HTMLFormHandler::Model;

=head1 DESCRIPTION

Using L<User::Config::UI::HTMLFormHandler> as UI, the form is generated to fit
to the options set by the different modules using L<User::Config>. With this
model it is possible to let L<HTML::FormHandler> handle the update of the
different settings, after the user made them.

=head2 METHODS

See L<HTML::FormHandler> for more information about C<$self->update_model()>
and C<$self->build_item()>.

=cut

sub _fieldname2obj {
	my ($field) = @_;
	local @_ = split /\./,$field->name;
	pop if $_[-1] =~ m/^_hfh_/;
	my $method = pop;
	return join("::"), $method;
}

sub update_model {
	my ($self) = @_;
	for(@{$self->fields}) {
		next if($_->value eq $_->init_value);
		my ($object, $method) = _fieldname2obj($_);
		$object->$method($self->{item_class}, $_->value);
	}
}

sub build_item {
	my ($self) = @_;
	for(@{$self->fields}) {
		my ($object, $method) = _fieldname2obj($_);
		my $val = $object->$method($self->{item_class});
		$_->init_value($val);
		$_->value($val);
	}
}

=head1 AUTHOR

Benjamin Tietz E<lt>benjamin@micronet24.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Benjamin Tietz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

