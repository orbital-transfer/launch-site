use Modern::Perl;
package Oberth::Prototype::System::Role::Perl;
# ABSTRACT: Role for Perls

use Mu::Role;
use Oberth::Manoeuvre::Common::Setup;

use File::Spec;
use Oberth::Prototype::Environment::Perl;

use Oberth::Prototype::EnvironmentVariables;
use Object::Util;

requires 'environment';
requires 'perl_path';
requires 'runner';

lazy author_perl => method() {
	$self->_get_perl_with_base_directory( $self->config->build_tools_dir );
};

lazy build_perl => method() {
	$self->_get_perl_with_base_directory( $self->config->lib_dir );
};

method _get_perl_with_base_directory( $directory ) {
	my $env = Oberth::Prototype::EnvironmentVariables->new(
		parent => $self->environment,
	)->$_tap( 'prepend_path_list', 'PATH', [
		map {
			File::Spec->catfile( $directory, $_ )
		} @{ Oberth::Prototype::BIN_DIRS() }
	]);
	Oberth::Prototype::Environment::Perl->new(
		perl => $self->perl_path,
		runner => $self->runner,
		parent_environment => $env,
		library_paths => [
			map {
				File::Spec->catfile( $directory, $_ )
			} @{ ( Oberth::Prototype::PERL_LIB_DIRS() ) }
		],
	);
}

1;
