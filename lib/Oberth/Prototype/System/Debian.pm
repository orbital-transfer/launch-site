use Modern::Perl;
package Oberth::Prototype::System::Debian;
# ABSTRACT: Debian-based system

use Mu;
use Oberth::Manoeuvre::Common::Setup;
use Oberth::Prototype::System::Debian::Meson;

use Env qw($DISPLAY);

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
	my @packages = qw(xvfb xauth);

	if( $> != 0 ) {
		warn "Not installing @packages";
	} else {
		system(qw(apt-get install -y --no-install-recommends), @packages);
	}
}

method install_packages($repo) {
	my @packages = @{ $repo->debian_get_packages };

	if( @packages ) {
		if( $> != 0 ) {
			warn "Not installing @packages";
		} else {
			system(qw(apt-get install -y --no-install-recommends), @packages );
		}
	}

	if( grep { $_ eq 'meson' } @packages ) {
		Oberth::Prototype::System::Debian::Meson->setup;
	}
}


1;
