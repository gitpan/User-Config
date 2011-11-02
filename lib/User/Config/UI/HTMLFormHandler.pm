package User::Config::UI::HTMLFormHandler;

use strict;
use warnings;

our $VERSION = '0.01_00';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

use User::Config::UI::HTMLFormHandler::Model;
use Moose;
extends 'HTML::FormHandler';
with 'User::Config::UI';

=head1 NAME

User::Config::UI::HTMLFormHandler - generate a userinterface for
L<User::Config> using a web-form.

=head1 SYNOPSIS

  use User::Config;
  use CGI qw/:cgi-lib/;

  my $uc = User::Config->instance;
  my $ui = $uc->ui("HTMLFormHandler");
  my $params = Vars;
  my $form->generate($params);
    ...
  print $form->render;

=head1 DESCRIPTION

Using this module, a form is generated containing all visible options
for L<User::Config>. The C<generate>-method will also process the parameters,
if any are given. Either way a fully functional <HTML::FormHandler>-object is
returned.

=cut

# perform common operations on a form element
sub _form_entry_general {
	my ($opt, $form) = @_;
	$form->{validate} = $opt->{validate} if $opt->{validate};
	return $form;
}

# generate a selection; maybe with a user-selectable entry.
sub _get_form_selection {
	my ($opt, $name) = @_;
	my @presets;
	my $withtext;
	for(keys(%{$opt->{presets}})) {
		push(@presets, { label => $_, value => $opt->{presets}->{$_}});
		if(not defined($opt->{presets}->{$_})) {
			$withtext = 1;
		}
	}
	my $ret = {
		type => 'Select',
		multiple => 1,
		options => \@presets,
	};
       	return _form_entry_general($opt, $ret) unless $withtext;
	$ret->{javascript} = "onchange=\"if(document.getElementById('$name.select').value == '' ) { document.getElementById('$name.text').display('block'); } else { document.getElementById('$name.text').display('none') }\"";
	$ret->{id} = $name.".select";
	return _form_entry_general($opt, { type => 'Compound', }),
	$name."._hfh_select" => $ret,
	$name."._hfh_text" => {
		type => 'Text',
		id => $name.".text",
		javascript => "display=\"none\"",
	};
}

# generate a form-entry with a given range
sub _get_form_range {
	my ($opt, $name) = @_;
	return _form_entry_general $opt, {
		type => ($opt->{ui_type} || 'Integer'),
		range_start => $opt->{range}->[0],
		range_end => $opt->{range}->[-1],
	};
}

# generate a form-entry from a corresponding option
sub _get_form_entry {
	my ($opt, $name) = @_;
	return _get_form_selection($opt, $name) if $opt->{presets};
	return _get_form_range($opt, $name) if $opt->{range};
	my $form;
	$form->{type} = $opt->{ui_type} || $opt->{isa} || 'Text';
	$form->{validate} = $opt->{validate} if $opt->{validate};
	return _form_entry_general $opt, $form;
}

# generate a list of form-entries from a list of options
sub _opt2form {
	my ($opts, $prefix) = @_;
	my $pprefix = $prefix;
	$pprefix .= "." if $pprefix;
	my @ret;
	for(keys %{$opts}) {
		my $subprefix = $pprefix.$_;
		my $topt = $opts->{$_};
		if($topt->{is_option}) {
			push(@ret, $subprefix => _get_form_entry($topt, $subprefix));
		} elsif($prefix) {
			push(@ret, $prefix => { type => 'Compound', }, _opt2form($topt, $subprefix));
		} else {
			push(@ret, _opt2form($topt, $subprefix));
		}
	}
	return @ret;
}

=head2 ATTRIBUTES

=head3 context

This will set the context L<User::Config> is working in. By default, this will
be the global context.

=cut

has 'context' => (
	default => User::Config->instance->context,
       	is => "rw",
);

=head3 form_options

This attribute will contain all additional parameters used while generating
the L<HTML::FormHandler>-object.

=cut

has 'form_options' => (
	default => sub { {} },
       	is => "rw"
);

=head3 params

the CGI-parameters given

=cut

has 'params' => is => "rw";

=head2 METHODS

=head3 C<$self->generate()>

generates a new L<HTML::FormHandler>-object. Optionally a hash-ref containing
the actual CGI-parameters can be submitted. This will replace the parameters
set within the current instance.

=cut

sub generate {
	my ($self, $params) = @_;
	my $init = $self->form_options;
	$init->{field_list} = [ _opt2form($self->get_options, "") ];
	my $ret = HTML::FormHandler->new(%{$init});
	$ret->{item_class} = $self->context;
	$params = $self->params unless $params;
	$ret->process($params) if $params;
	return $ret;
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

