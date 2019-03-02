use Modern::Perl;
package Oberth::Prototype::Repo::Role::DistZilla;
# ABSTRACT: A role for Dist::Zilla repos

use Mu::Role;

use File::Which;
use Module::Load;
use Capture::Tiny qw(capture);
use File::Temp qw(tempdir);
use File::chdir;

use Oberth::Manoeuvre::Common::Setup;
use Oberth::Prototype::System::Debian::Meson;
use Oberth::Prototype::EnvironmentVariables;

lazy environment => method() {
	my $parent = $self->platform->environment;
	my $env = Oberth::Prototype::EnvironmentVariables->new(
		parent => $parent
	);

	my @packages = @{ $self->debian_get_packages };
	if( grep { $_ eq 'meson' } @packages ) {
		my $meson = Oberth::Prototype::System::Debian::Meson->new(
			runner => $self->runner
		);
		push @{ $env->_commands }, @{ $meson->environment->_commands };
	}

	$env;
};

lazy test_environment => method() {
	my $env = Oberth::Prototype::EnvironmentVariables->new(
		parent => $self->environment
	);
};

method _install_perl_deps_cpanm_dir_arg() {
	my $global = $self->config->cpan_global_install;

	@{ $global ? [] : [ qw(-L), $self->config->lib_dir ] };
}

method install_perl_build( @dists ) {
	my $global = $self->config->cpan_global_install;
	try {
	$self->platform->author_perl->script('cpm',
			qw(install),
			@{ $global ? [ qw(-g) ] : [ qw(-L), $self->config->build_tools_dir ] },
			@dists
	);
	} catch { };
	$self->platform->author_perl->script('cpanm',
		qw(-qn),
		@{ $global ? [] : [ qw(-L), $self->config->build_tools_dir ] },
		@dists
	);
}

method install_perl_deps( @dists ) {
	my $global = $self->config->cpan_global_install;
	# TODO ignore modules that are installed already: --skip-installed
	try {

	$self->platform->build_perl->script(
		qw(cpm install),
		@{ $global ? [ qw(-g) ] : [ qw(-L), $self->config->lib_dir ] },
		@dists
	);

	$self->platform->build_perl->script(
		qw(cpanm -qn),
		$self->_install_perl_deps_cpanm_dir_arg,
		@dists
	);

	} catch { };
}

method _install_dzil() {
	try {
		$self->runner->system(
			$self->platform->author_perl->command(
				qw(-MDist::Zilla -e1),
			)
		);
	} catch {
		$self->install_perl_build(qw(Net::SSLeay Dist::Zilla));
	};
}

method _get_dzil_authordeps() {
	local $CWD = $self->directory;

	my ($dzil_authordeps, $dzil_authordeps_stderr, $dzil_authordeps_exit) = capture {
		try {
			$self->platform->author_perl->script(
				qw(dzil authordeps)
				# --missing
			);
		} catch {};
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
		$self->platform->author_perl->script(
			qw(dzil listdeps)
			# --missing
		)
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

	$self->platform->author_perl->script(
		'dzil', qw(build --in), $self->dzil_build_dir
	);

	$self->platform->build_perl->script(
		'cpanm', qw(-qn),
		qw(--installdeps),
		$self->_install_perl_deps_cpanm_dir_arg,
		$self->dzil_build_dir
	);
}

method _dzil_has_plugin_test_podspelling() {
	return 1;

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
			$self->platform->apt->install_packages_command(
				map {
					Oberth::Prototype::RepoPackage::APT->new( name => $_ )
				} qw(aspell aspell-en)
			)
		);
	}
}

method setup_build() {
	$self->_install_dzil;
	$self->_install_dzil_authordeps;
	$self->_install_dzil_spell_check_if_needed;

	$self->_install_dzil_listdeps;
	$self->_install_dzil_build;
}

method install() {
	local $CWD = $self->directory;

	$self->platform->author_perl->script(
		qw(dzil build --in), $self->dzil_build_dir
	);

	$self->platform->build_perl->script(
		qw(cpanm --notest),
		qw(--no-man-pages),
		$self->_install_perl_deps_cpanm_dir_arg,
		$self->dzil_build_dir
	);
}

method run_test() {
	my $test_env = $self->test_environment;
	local $CWD = $self->directory;

	$self->platform->author_perl->script(
		qw(dzil build --in), $self->dzil_build_dir
	);

	if( $self->config->has_oberth_coverage ) {
		# Need to have at least Devel::Cover~1.31 for fix to
		# "Devel::Cover hangs when used with Function::Parameters"
		# GH#164 <https://github.com/pjcj/Devel--Cover/issues/164>.
		$self->platform->build_perl->script(
			qw(cpanm),
			qw(--no-man-pages),
			$self->_install_perl_deps_cpanm_dir_arg,
			qw(--notest),
			qw(Devel::Cover~1.31)
		);

		$test_env->append_string(
			'HARNESS_PERL_SWITCHES', " -MDevel::Cover"
		);


		if( $self->config->oberth_coverage eq 'coveralls' ) {
			$self->platform->build_perl->script(
				qw(cpanm),
				qw(--no-man-pages),
				$self->_install_perl_deps_cpanm_dir_arg,
				qw(--notest),
				qw(Devel::Cover::Report::Coveralls)
			);
		}
	}

	$self->platform->build_perl->script(
		qw(cpanm),
		qw(--no-man-pages),
		$self->_install_perl_deps_cpanm_dir_arg,
		qw(--verbose),
		qw(--test-only),
		$self->dzil_build_dir
	);

	if( $self->config->has_oberth_coverage ) {
		local $CWD = File::Spec->catfile( $self->directory, $self->dzil_build_dir );
		if( $self->oberth_coverage eq 'coveralls' ) {
			$self->platform->build_perl->script(
				qw(cover), qw(-report coveralls)
			);
		} else {
			$self->platform->build_perl->script(
				qw(cover),
			);
		}
	}
}

1;
