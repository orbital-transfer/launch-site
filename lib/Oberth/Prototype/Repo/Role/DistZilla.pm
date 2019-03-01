use Modern::Perl;
package Oberth::Prototype::Repo::Role::DistZilla;
# ABSTRACT: A role for Dist::Zilla repos

use Mu::Role;

use File::Which;
use Module::Load;
use Capture::Tiny qw(capture);
use File::Temp qw(tempdir);
use File::chdir;

use Env qw(@PERL5LIB $HARNESS_PERL_SWITCHES $OBERTH_COVERAGE);

use Oberth::Manoeuvre::Common::Setup;
use Oberth::Prototype::System::Debian::Meson;

method _env() {
	my @packages = @{ $self->debian_get_packages };
	if( grep { $_ eq 'meson' } @packages ) {
		Oberth::Prototype::System::Debian::Meson->_env;
	}
}

method _run_with_build_perl($code) {
	my @OLD_PERL5LIB = @PERL5LIB;

	my $lib_dir = $self->config->build_tools_dir;

	unshift @PERL5LIB, File::Spec->catfile( $lib_dir, $_ ) for @{ (Oberth::Prototype::PERL_LIB_DIRS()) };

	my @return = $code->();

	@PERL5LIB = @OLD_PERL5LIB;

	@return;
}

method _install_perl_deps_cpanm_dir_arg() {
	my $global = $self->config->cpan_global_install;

	@{ $global ? [] : [ qw(-L), $self->config->lib_dir ] };
}

method install_perl_build( @dists ) {
	my $global = $self->config->cpan_global_install;
	system(qw(cpm install),
		@{ $global ? [ qw(-g) ] : [ qw(-L), $self->config->build_tools_dir ] },
		@dists);
	system(qw(cpanm -qn),
		@{ $global ? [] : [ qw(-L), $self->config->build_tools_dir ] },
		@dists);
}

method install_perl_deps( @dists ) {
	my $global = $self->config->cpan_global_install;
	system(qw(cpm install),
		@{ $global ? [ qw(-g) ] : [ qw(-L), $self->config->lib_dir ] },
		@dists);
	system(qw(cpanm -qn),
		$self->_install_perl_deps_cpanm_dir_arg,
		@dists);
}

method _install_dzil() {
	unless( which 'dzil' ) {
		$self->install_perl_build(qw(Dist::Zilla));
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
		$self->install_perl_build( @dzil_authordeps );
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
	if( @dzil_deps ) {
		$self->install_perl_deps(@dzil_deps);
	}

}

lazy dzil_build_dir => method() {
	qq(../build-dir);
};

method _install_dzil_build() {
	local $CWD = $self->directory;
	$self->_run_with_build_perl(sub {
		system(qw(dzil build --in), $self->dzil_build_dir );
	});
	use autodie qw(system);
	system(qw(cpanm -qn),
		qw(--installdeps),
		$self->_install_perl_deps_cpanm_dir_arg,
		$self->dzil_build_dir );
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

	require Oberth::Prototype::RepoPackage::APT;
	if( $self->_dzil_has_plugin_test_podspelling ) {
		$self->runner->system(
			$self->config->platform->apt->install_packages_command(
				map {
					Oberth::Prototype::RepoPackage::APT->new( name => $_ )
				} qw(aspell aspell-en)
			)
		);
	}
}

method setup_build() {
	$self->_env;
	$self->_install_dzil;
	$self->_install_dzil_authordeps;
	$self->_install_dzil_spell_check_if_needed;

	$self->_install_dzil_listdeps;
	$self->_install_dzil_build;
}

method install() {
	$self->_env;
	local $CWD = $self->directory;
	$self->_run_with_build_perl(sub {
		system(qw(dzil build --in), $self->dzil_build_dir );
	});
	system(qw(cpanm --notest),
		qw(--no-man-pages),
		$self->_install_perl_deps_cpanm_dir_arg,
		$self->dzil_build_dir );
}

method run_test() {
	$self->_env;
	local $CWD = $self->directory;
	$self->_run_with_build_perl(sub {
		system(qw(dzil build --in), $self->dzil_build_dir );
	});

	use autodie qw(system);
	my $OLD_HARNESS_PERL_SWITCHES = $HARNESS_PERL_SWITCHES;

	if( exists $ENV{OBERTH_COVERAGE} && $ENV{OBERTH_COVERAGE} ) {
		# Need to have at least Devel::Cover~1.31 for fix to
		# "Devel::Cover hangs when used with Function::Parameters"
		# GH#164 <https://github.com/pjcj/Devel--Cover/issues/164>.
		system(qw(cpanm --notest),
			qw(--no-man-pages),
			$self->_install_perl_deps_cpanm_dir_arg,
			qw(Devel::Cover~1.31) );

		$HARNESS_PERL_SWITCHES .= " -MDevel::Cover";

		if( $ENV{OBERTH_COVERAGE} eq 'coveralls' ) {
			system(qw(cpanm --notest),
				qw(--no-man-pages),
				$self->_install_perl_deps_cpanm_dir_arg,
				qw(Devel::Cover::Report::Coveralls) );
		}
	}

	system(qw(cpanm --test-only),
		qw(--verbose),
		qw(--no-man-pages),
		$self->_install_perl_deps_cpanm_dir_arg,
		$self->dzil_build_dir );

	if( exists $ENV{OBERTH_COVERAGE} && $ENV{OBERTH_COVERAGE} ) {
		local $CWD = File::Spec->catfile( $self->directory, $self->dzil_build_dir );
		if( $ENV{OBERTH_COVERAGE} eq 'coveralls' ) {
			system(qw(cover), qw(-report coveralls));
		} else {
			system(qw(cover));
		}
	}

	$HARNESS_PERL_SWITCHES = $OLD_HARNESS_PERL_SWITCHES;
}

1;
