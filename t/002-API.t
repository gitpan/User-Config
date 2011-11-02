use Test::More tests => 9;
eval { require Test::Pod::Coverage; };
my $podcoverage = $@;

use lib 't';

my $module;
BEGIN { $module = 'User::Config'};
BEGIN { use_ok($module) };

use User::Config::Test;
use User::Config::Test::rem;

my $mod = User::Config::Test->new;

$mod->context({user => "foo"});
$mod->setting("bar");
$mod->setting({user => "foobar"}, "hoho");

is($mod->setting, "bar", "Setting in modul context");
is($mod->setting({user => "foobar"}), "hoho", "Setting in specific context");
is($mod->setting({user => "unknown"}), "defstr", "Default setting");

my $remote = User::Config::Test::rem->new;

is($remote->remote({user => "foo"}), "bar", "setting references");

is($mod->dyndef, 1, "Dynamic default first user");
is($mod->dyndef({user => "foobar"}), 2, "Dynamic default second user");
is($mod->dyndef, 1, "rerequest the first users default");

SKIP: {
	skip "Test::Pod::Coverage isn't installed", 1 if $podcoverage;
	Test::Pod::Coverage::pod_coverage_ok($module, "$module Documentation is complete");
};

