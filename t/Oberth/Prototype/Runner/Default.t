#!/usr/bin/env perl

use Test::Most tests => 1;
use Modern::Perl;
use Object::Util;

use Oberth::Prototype::Runner::Default;
use Oberth::Prototype::Runnable;
use Oberth::Prototype::EnvironmentVariables;

my $runner = Oberth::Prototype::Runner::Default->new;

subtest "Set environment" => sub {
	my $cmd = [ qw(sh -c), q(echo -n $TEST_RUNNER) ];
	local $ENV{TEST_RUNNER} = 'first capture';
	my ($output_local) = $runner->capture(
		Oberth::Prototype::Runnable->new(
			command => $cmd,
		)
	);
	is $output_local, 'first capture', 'Uses the contents of %ENV';

	my $env_second = Oberth::Prototype::EnvironmentVariables
		->new
		->$_tap( set_string => 'TEST_RUNNER', 'second capture' );
	my ($output_env_second) = $runner->capture(
		Oberth::Prototype::Runnable->new(
			command => $cmd,
			environment => $env_second,
		)
	);
	is $output_env_second, 'second capture',
		'Uses the contents of EnvironmentVariables object';

	my $env_third = Oberth::Prototype::EnvironmentVariables
		->new( parent => $env_second )
		->$_tap( 'prepend_string', 'TEST_RUNNER', 'another ' );
	my ($output_env_third) = $runner->capture(
		Oberth::Prototype::Runnable->new(
			command => $cmd,
			environment => $env_third,
		)
	);
	is $output_env_third, 'another second capture',
		'Uses the contents of EnvironmentVariables object (inherit)';
};

done_testing;
