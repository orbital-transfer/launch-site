use Modern::Perl;
package Oberth::Prototype::Repo::Role::DistZilla;
# ABSTRACT: A role for Dist::Zilla repos

use Mu::Role;

use File::Which;
use Module::Load;
use Capture::Tiny qw(capture);
use File::Temp qw(tempdir);
use File::chdir;

use Env qw(@PERL5LIB);

use Oberth::Common::Setup;

method _run_with_build_perl($code) {
	my @OLD_PERL5LIB = @PERL5LIB;

	my $lib_dir = $self->config->build_tools_dir;

	unshift @PERL5LIB, File::Spec->catfile( $lib_dir, $_ ) for @{ (Oberth::Prototype::PERL_LIB_DIRS()) };

	my @return = $code->();

	@PERL5LIB = @OLD_PERL5LIB;

	@return;
}

method _install_dzil() {
	unless( which 'dzil' ) {
		system(qw(cpm install),
			qw(-L ), $self->config->build_tools_dir,
			qw(Dist::Zilla));
	}
}

method _get_dzil_authordeps() {
	local $CWD = $self->directory;
	my ($dzil_authordeps, $dzil_authordeps_stderr, $dzil_authordeps_exit) = capture {
		$self->_run_with_build_perl(sub {
			system(qw(dzil authordeps)); # --missing
		});
	};

	my @dzil_authordeps = split /\n/, $dzil_authordeps;
}

method _install_dzil_authordeps() {
	my @dzil_authordeps = $self->_get_dzil_authordeps;
	if( @dzil_authordeps ) {
		system(qw(cpm install),
			qw(-L), $self->config->build_tools_dir,
			@dzil_authordeps);
		system(qw(cpanm -qn),
			qw(-L), $self->config->build_tools_dir,
			@dzil_authordeps);
	}
}

method _get_dzil_listdeps() {
	local $CWD = $self->directory;
	my ($dzil_deps, $dzil_deps_stderr, $exit_listdeps) = capture {
		$self->_run_with_build_perl(sub {
			system(qw(dzil listdeps)); # --missing
		});
	};
	my @dzil_deps = grep {
		$_ !~ /
			^\W
			| ^Possibly\ harmless
			| ^Attempt\ to\ reload.*aborted
			| ^BEGIN\ failed--compilation\ aborted
			| ^Can't\ locate.*in\ \@INC
			| ^Compilation\ failed\ in\ require
		/x
	} split /\n/, $dzil_deps;
}

method _install_dzil_listdeps() {
	my @dzil_deps = $self->_get_dzil_listdeps;
	my $global = 0;
	if( @dzil_deps ) {
		system(qw(cpm install),
			( $global ? qw(-g) : qw(-L), $self->config->lib_dir ),
			@dzil_deps);
		system(qw(cpanm -qn),
			( $global ? () : qw(-L), $self->config->lib_dir ),
			@dzil_deps);
	}
}

method _dzil_has_plugin_test_podspelling() {
	load 'Test::DZil';

	my $temp_dir = tempdir( CLEANUP => 1 );

	my $dz = Test::DZil::Builder()->from_config(
		{ dist_root => $self->directory },
		{ tempdir_root => $temp_dir },
	);

	my @plugins = @{ $dz->plugins };

	scalar grep { ref $_ eq 'Dist::Zilla::Plugin::Test::PodSpelling' } @plugins;
}


method _install_dzil_spell_check_if_needed() {
	return unless $^O eq 'linux';

	if( $self->_dzil_has_plugin_test_podspelling ) {
		system(qw(apt-get install -y --no-install-recommends aspell aspell-en));
	}
}

method setup_build() {
	$self->_install_dzil;
	$self->_install_dzil_authordeps;
	$self->_install_dzil_spell_check_if_needed;

	$self->_install_dzil_listdeps;
}

method install() {
	local $CWD = $self->directory;
	$self->_run_with_build_perl(sub {
		system(qw(dzil build --in ../build-dir) );
	});
	system(qw(cpanm --notest),
		qw(--no-man-pages),
		qw(-L), $self->config->lib_dir,
		qw(../build-dir) );
}

method run_test() {
	local $CWD = $self->directory;
	$self->_run_with_build_perl(sub {
		system(qw(dzil build --in ../build-dir) );
	});
	use autodie qw(system);
	system(qw(cpanm --test-only),
		qw(--verbose),
		qw(--no-man-pages),
		qw(-L), $self->config->lib_dir,
		qw(../build-dir) );
}

1;
