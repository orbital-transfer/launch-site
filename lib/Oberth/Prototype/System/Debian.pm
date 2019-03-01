use Modern::Perl;
package Oberth::Prototype::System::Debian;
# ABSTRACT: Debian-based system

use Mu;
use Oberth::Manoeuvre::Common::Setup;
use Oberth::Prototype::System::Debian::Meson;
use Oberth::Prototype::Runner::Default;

use Oberth::Prototype::PackageManager::APT;
use Oberth::Prototype::RepoPackage::APT;

use Env qw($DISPLAY);

lazy runner => method() {
	Oberth::Prototype::Runner::Default->new;
};

lazy apt => method() {
	Oberth::Prototype::PackageManager::APT->new(
		runner => $self->runner
	);
};

method _env() {
	$DISPLAY=':99.0';
}

method _prepare_x11() {
	#system(qw(sh -e /etc/init.d/xvfb start));
	unless( fork ) {
		exec(qw(Xvfb), $DISPLAY);
	}
	sleep 3;
}

method _pre_run() {
	$self->_prepare_x11;
}

method _install() {
	my @packages = map {
		Oberth::Prototype::RepoPackage::APT->new( name => $_ )
	} qw(xvfb xauth);
	$self->runner->system(
		$self->apt->install_packages_command(@packages)
	);
}

method install_packages($repo) {
	my @packages = map {
		Oberth::Prototype::RepoPackage::APT->new( name => $_ )
	} @{ $repo->debian_get_packages };

	$self->runner->system(
		$self->apt->install_packages_command(@packages)
	) if @packages;

	if( grep { $_->name eq 'meson' } @packages ) {
		Oberth::Prototype::System::Debian::Meson->setup;
	}
}

1;
