use Modern::Perl;
package Oberth::Prototype::System::Debian;
# ABSTRACT: Debian-based system

use Mu;
use Oberth::Common::Setup;

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
	system(qw(apt-get install -y --no-install-recommends xvfb xauth));
}

method install_packages($repo) {
	my @packages = @{ $repo->debian_get_packages };
	if( @packages ) {
		system(qw(apt-get install -y --no-install-recommends), @packages );
	}
}


1;
