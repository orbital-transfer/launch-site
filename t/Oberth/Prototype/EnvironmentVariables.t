#!/usr/bin/env perl

use Test::Most tests => 2;
use Modern::Perl;
use Object::Util;

use Oberth::Prototype::EnvironmentVariables;
use Config;

my $sep = $Config{path_sep};

subtest "Paths: prepend" => sub {
	my $env = Oberth::Prototype::EnvironmentVariables->new
		->new;

	ok ! exists $env->environment_hash->{TEST_PATH};

	$env->prepend_path_list( 'TEST_PATH', [ 'a' ]  );
	is $env->environment_hash->{TEST_PATH}, 'a';

	$env->prepend_path_list( 'TEST_PATH', [ 'b' ]  );
	is $env->environment_hash->{TEST_PATH}, "b${sep}a";

	$env->prepend_path_list( 'TEST_PATH', [ 'c', 'd' ]  );
	is $env->environment_hash->{TEST_PATH}, "c${sep}d${sep}b${sep}a";

};

subtest "Paths: append" => sub {
	my $env = Oberth::Prototype::EnvironmentVariables->new
		->new;

	ok ! exists $env->environment_hash->{TEST_PATH};

	$env->append_path_list( 'TEST_PATH', [ 'a' ]  );
	is $env->environment_hash->{TEST_PATH}, 'a';

	$env->append_path_list( 'TEST_PATH', [ 'b' ]  );
	is $env->environment_hash->{TEST_PATH}, "a${sep}b";

	$env->append_path_list( 'TEST_PATH', [ 'c', 'd' ]  );
	is $env->environment_hash->{TEST_PATH}, "a${sep}b${sep}c${sep}d";

};

done_testing;
