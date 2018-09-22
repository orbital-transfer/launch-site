use Modern::Perl;
package Oberth::Prototype::System::MacOSHomebrew;
# ABSTRACT: macOS with homebrew

use Mu;
use Oberth::Common::Setup;
use IPC::System::Simple ();

use Env qw(@PATH @PKG_CONFIG_PATH $ARCHFLAGS);

method _env() {
	# Set up for OpenSSL (linking and utilities)
	unshift @PKG_CONFIG_PATH, '/usr/local/opt/openssl/lib/pkgconfig';
	unshift @PATH, '/usr/local/opt/openssl/bin';

	# Set up for libffi linking
	unshift @PKG_CONFIG_PATH, '/usr/local/opt/libffi/lib/pkgconfig';

	# Add Homebrew gettext utilities to path
	unshift @PATH, '/usr/local/opt/gettext/bin';

	$ARCHFLAGS='-arch x86_64';
}

method _pre_run() {

}

method _install() {
	say STDERR "Updating homebrew";
	system(qw(brew update));

	# Set up for X11 support
	say STDERR "Installing xquartz homebrew cask for X11 support";
	system(qw(brew tap Caskroom/cask));
	system(qw(brew install Caskroom/cask/xquartz));

	# Set up for pkg-config
	system(qw(brew install pkg-config));

	# Set up for OpenSSL (linking and utilities)
	system(qw(brew install openssl));
}

method install_packages($repo) {
	my @packages = @{ $repo->homebrew_get_packages };
	say STDERR "Installing repo native deps";
	if( @packages ) {
		# Skip font cache generation (for fontconfig):
		# <https://github.com/Homebrew/homebrew-core/pull/10947#issuecomment-285946088>
		my $has_fontconfig_dep = eval {
			use autodie qw(:system);
			system( qq{brew deps --union @packages | grep ^fontconfig\$ && brew install --force-bottle --build-bottle fontconfig} );
		};

		my @deps_to_install = grep {
			my $dep = $_;
			eval {
				use autodie qw(:system);
				system( qq{brew ls @packages >/dev/null 2>&1} );
			};
			$@ ? 1 : 0;
		} @packages;
		say STDERR "Native deps to install: @deps_to_install";

		if(@deps_to_install) {
			system( qq{brew install @deps_to_install || true} );
			system( qq{brew install @packages || true} );
		}
	}
}

1;
