use Test::More tests => 5;
use lib 't';

use User::Config;
use User::Config::Test;
use DBI;

my $module;
BEGIN { $module = 'User::Config::DB::DBIC'};
BEGIN { use_ok($module) };

my $dbfile;
my $table;
my $dbcon;
BEGIN {
	$dbfile = "dbic.db";
	$table = "test";
	unlink $dbfile if -f $dbfile;
	$dbcon = "dbi:SQLite:$dbfile";
	my $dbh = DBI->connect($dbcon, undef, undef, { AutoCommit => 1 });
	$dbh->do("CREATE TABLE $table ( uid text primary key, User_Config_Test_setting text )");
}

my $uc = User::Config::instance();
ok($uc->db("DBIC", { db => $dbcon, schema => 'User::Config::Test::Schema', resultset => 'Test' }), "DBIC DB-client connected");
my $mod = User::Config::Test->new;
$mod->context({user => "foo"});
is($mod->setting, "defstr", "Default value");
$mod->setting("bla");
is($mod->setting, "bla", "saved DBIC setting");
$mod->setting("blablupp");
is($mod->setting, "blablupp", "modified DBIC setting");
