use Modern::Perl;
package Oberth::Prototype::System::Debian::Meson;
# ABSTRACT: Install and setup meson build system

use Mu;
use Oberth::Manoeuvre::Common::Setup;
use Env qw(@PATH @PYTHONPATH);

method _env() {
	chomp( my $py_user_base_bin = `python3 -c "import site, os; print(os.path.join(site.USER_BASE, 'bin'))"` );
	chomp( my $py_user_site_pypath = `python3 -c "import site; print(site.USER_SITE)"` );
	unshift @PATH, $py_user_base_bin;
	unshift @PYTHONPATH, $py_user_site_pypath;
}

method setup() {
	$self->_env;
	if( $> != 0 ) {
		warn "Not installing meson";
	} else {
		system(qw(apt-get install -y --no-install-recommends python3-pip));
		system(qw(pip3 install --user -U setuptools));
		system(qw(pip3 install --user -U meson));
	}
}

1;
