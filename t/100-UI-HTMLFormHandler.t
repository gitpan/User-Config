use Test::More tests => 3;
BEGIN {
	# prevent Test::Deep::blessed from being exported
	require Test::Deep;
	Test::Deep->import( grep { $_ ne "blessed" } @Test::Deep::EXPORT );
}

my $module;
BEGIN { $module = 'User::Config::UI::HTMLFormHandler'};
BEGIN { use_ok($module) };

use lib 't';
use User::Config;
use User::Config::Test;
use User::Config::Test::rem;

my $form = User::Config->ui("HTMLFormHandler")->generate;
is(ref $form, "HTML::FormHandler", "generated HTML::FormHandler");
cmp_deeply([$form->fields], noclass([
	superhashof({
			name => 'User',
			type => 'Compound',
			fields => [superhashof({
					name => 'Config',
					type => 'Compound',
					fields => [superhashof({
							name => 'Test',
							type => 'Compound',
							fields => bag(
								superhashof({
									name => 'setting',
									type => 'Text',
								}),
								superhashof({
									name => 'dyndef',
								}),
							)
						})]
				})]
		})
	]), "all fields present");
