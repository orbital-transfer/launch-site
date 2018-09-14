use Modern::Perl;
package Oberth::Prototype::Repo::Role::DistZilla;
# ABSTRACT: A role for Dist::Zilla repos

use Mu::Role;

use File::Which;
use Module::Load;
use Capture::Tiny qw(capture);
use File::Temp qw(tempdir);
use File::chdir;

use Oberth::Common::Setup;

method _install_dzil() {
	unless( which 'dzil' ) {
		system(qw(cpm install -L ), $self->config->build_tools_dir, qw(Dist::Zilla));
	}
}

method _get_dzil_authordeps() {
	local $CWD = $self->directory;
	my ($dzil_authordeps, $dzil_authordeps_stderr, $dzil_authordeps_exit) = capture {
		system(qw(dzil authordeps)); # --missing
	};
	my @dzil_authordeps = split /\n/, $dzil_authordeps;
}

method _install_dzil_authordeps() {
	my @dzil_authordeps = $self->_get_dzil_authordeps;
	if( @dzil_authordeps ) {
		system(qw(cpm install -L), $self->config->build_tools_dir, @dzil_authordeps);
		system(qw(cpanm -qn -L), $self->config->build_tools_dir, @dzil_authordeps);
	}
}

method _get_dzil_listdeps() {
	local $CWD = $self->directory;
	my ($dzil_deps, $dzil_deps_stderr, $exit_listdeps) = capture {
		system(qw(dzil listdeps)); # --missing
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
		system(qw(cpm install -L), $self->config->lib_dir, @dzil_deps);
		system(qw(cpanm -qn -L), $self->config->lib_dir, @dzil_deps);
	}
}

method _install_dzil_spell_check_if_needed() {
	return unless $^O eq 'linux';

	load 'Test::DZil';

	my $temp_dir = tempdir( CLEANUP => 1 );

	my $dz = Test::DZil::Builder()->from_config(
		{ dist_root => $self->directory },
		{ tempdir_root => $temp_dir },
	);

	my @plugins = @{ $dz->plugins };

	if( grep { ref $_ eq 'Dist::Zilla::Plugin::Test::PodSpelling' } @plugins ) {
		system(qw(apt-get install -y --no-install-recommends aspell));
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
	system(qw(dzil build --in ../build-dir) );
	system(qw(cpanm --notest ../build-dir) );
}

method run_test() {
	local $CWD = $self->directory;
	system(qw(dzil test));
}

1;
