use Test::More skip_all => "Tested by API-tests"; #tests => 1;

my $module;
BEGIN { $module = 'User::Config::DB::Mem'};
BEGIN { use_ok($module) };

