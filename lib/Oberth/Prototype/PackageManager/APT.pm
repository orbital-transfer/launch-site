use Modern::Perl;
package Oberth::Prototype::PackageManager::APT;
# ABSTRACT: Package manager for apt-based systems

use Mu;
use Oberth::Manoeuvre::Common::Setup;
use aliased 'Oberth::Prototype::Runnable';
use Oberth::Prototype::PackageManager::dpkg;
use List::AllUtils qw(all);

lazy dpkg => method() {
	Oberth::Prototype::PackageManager::dpkg->new(
		runner => $self->runner,
	);
};

method installed_version( $package ) {
	$self->dpkg->installed_version( $package );
}

method installable_versions( $package ) {
	try {
		my ($show_output) = $self->runner->capture(
			Runnable->new(
				command => [ qw(apt-cache show), $package->name ],
			)
		);

		my @package_info = split "\n\n", $show_output;

		map { /^Version: (\S+)$/ms } @package_info;
	} catch {
		die "apt-cache: Unable to locate package @{[ $package->name ]}";
	};
}

method are_all_installed( @packages ) {
	all { $self->installable_versions( $_ ) } @packages;
}

method install_packages_command( @package ) {
	Runnable->new(
		command => [
			qw(apt-get install -y --no-install-recommends),
			map { $_->name } @package
		],
		admin_privilege => 1,
	);
}

with qw(Oberth::Prototype::Role::HasRunner);

1;
