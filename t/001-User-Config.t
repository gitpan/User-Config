# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl User-Config.t'

# This test just will try to load all Modules provide. The functionality
# will be tested later on.

#########################

use Test::More tests => 6;
use_ok('User::Config');
use_ok('User::Config::UI::HTMLFormHandler');
use_ok('User::Config::DB::Mem');
use_ok('User::Config::DB::Ldap');
use_ok('User::Config::DB::DBIC');
use_ok('User::Config::DB::Keyed');

#########################
