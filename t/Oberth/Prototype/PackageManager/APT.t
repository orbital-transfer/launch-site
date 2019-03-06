#!/usr/bin/env perl

use Test::Most tests => 2;

use Oberth::Prototype::PackageManager::APT;
use Oberth::Prototype::Runner::Default;
use Oberth::Prototype::RepoPackage::APT;
use aliased 'Oberth::Prototype::Runnable';

sub init {
	my $runner = Oberth::Prototype::Runner::Default->new;
	my $apt = Oberth::Prototype::PackageManager::APT->new( runner => $runner );

	($runner, $apt);
}

subtest "dpkg package" => sub {
	my ($runner, $apt) = init;

	my $package = Oberth::Prototype::RepoPackage::APT->new( name => 'dpkg' );
	my $version = $apt->installed_version( $package );

	my ($expected_version) = $runner->capture( Runnable->new(
		command => [ qw(dpkg --version) ]
	) ) =~ /program version (\S+)/m;

	is $version, $expected_version, 'correct version';

	my @versions = $apt->installable_versions( $package );
	ok grep { $_ eq $expected_version } @versions, 'dpkg is up to date with installable versions';
};

subtest "Non-existent package" => sub {
	my ($runner, $apt) = init;

	my $package = Oberth::Prototype::RepoPackage::APT->new( name => 'not-a-real-package' );
	throws_ok { $apt->installed_version( $package ) } qr/no packages found/;

	throws_ok { $apt->installable_versions( $package ) } qr/Unable to locate package/;
};

done_testing;
