use Test::More;
use Catalyst::Helper;

use lib 't';

BEGIN {
	eval { require Catalyst::Devel };
	plan skip_all => "No Catalyst::Devel present" if $@;
	plan tests => 2 + 4 * 3;
}

my $module;
BEGIN { $module = 'Catalyst::Helper::Model::UserConfig'};
BEGIN { use_ok($module) };

sub test_generator {
	my ( $type, @args ) = @_;
	my $cls = "UserConfigTest$type";
	my $fn = "$cls.pm";
	unlink $fn if -f $fn;
	my $helper = bless({
			file => $fn,
			app => "TestApp",
			class => $cls,
		}, 'Catalyst::Helper');
	$module->mk_compclass($helper, $type, @args);
	require_ok($cls);

	is(ref User::Config->instance->db, "User::Config::DB::$type",
		"set correct database for $type");
	SKIP: {
		eval "use Test::Pod 1.00";
		skip "Test::Pod required to test POD", 1 if $@;
		Test::Pod::pod_file_ok($fn, "created valid POD for $type");
	}
	unlink $fn if -f $fn;
}
test_generator("Mem");
test_generator("DBIC", "dbi:SQLite:dbic.db", "User::Config::Test::Schema", "Test");
test_generator("Ldap", "ldap://localhost", "dc=localhost");
test_generator("Keyed", "dbi:SQLite:keyed.db", "test");
is(ref UserConfigTestMem::form(User::Config->instance), "User::Config::UI::HTMLFormHandler", "embedded UI handler");
