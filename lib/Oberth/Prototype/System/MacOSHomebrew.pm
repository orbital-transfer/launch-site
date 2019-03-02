use Modern::Perl;
package Oberth::Prototype::System::MacOSHomebrew;
# ABSTRACT: macOS with homebrew

use Mu;
use Oberth::Manoeuvre::Common::Setup;
use IPC::System::Simple ();

use Oberth::Prototype::EnvironmentVariables;
use Oberth::Prototype::Runner::Default;
use aliased 'Oberth::Prototype::Runnable';

lazy environment => method() {
	my $env = Oberth::Prototype::EnvironmentVariables
		->new;

	# Set up for OpenSSL (linking and utilities)
	$env->prepend_path_list( 'PKG_CONFIG_PATH', [ '/usr/local/opt/openssl/lib/pkgconfig' ]  );
	$env->prepend_path_list( 'PATH', [ '/usr/local/opt/openssl/bin' ]  );

	# Set up for libffi linking
	$env->prepend_path_list( 'PKG_CONFIG_PATH', [ '/usr/local/opt/libffi/lib/pkgconfig' ]  );

	# Add Homebrew gettext utilities to path
	$env->prepend_path_list( 'PATH', [ '/usr/local/opt/gettext/bin' ]  );

	$env->set_string('ARCHFLAGS', '-arch x86_64' );

	$env;
};

method _pre_run() {

}

method _install() {
	say STDERR "Updating homebrew";
	$self->runner->system(
		Runnable->new(
			command => [ qw(brew update) ]
		)
	);

	# Set up for X11 support
	say STDERR "Installing xquartz homebrew cask for X11 support";
	$self->runner->system(
		Runnable->new(
			command => $_
		)
	) for (
		[ qw(brew tap Caskroom/cask) ],
		[ qw(brew install Caskroom/cask/xquartz) ]
	);

	# Set up for pkg-config
	$self->runner->system(
		Runnable->new(
			command => [ qw(brew install pkg-config) ]
		)
	);

	# Set up for OpenSSL (linking and utilities)
	$self->runner->system(
		Runnable->new(
			command => [ qw(brew install openssl) ]
		)
	);
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

with qw(
	Oberth::Prototype::System::Role::Config
	Oberth::Prototype::System::Role::DefaultRunner
	Oberth::Prototype::System::Role::PerlPathCurrent
	Oberth::Prototype::System::Role::Perl
);

1;
