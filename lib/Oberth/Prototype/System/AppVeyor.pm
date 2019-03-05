use Modern::Perl;
package Oberth::Prototype::System::AppVeyor;
# ABSTRACT: AppVeyor system for MSYS2/MinGW64

use Mu;
use Oberth::Manoeuvre::Common::Setup;

use Oberth::Prototype::EnvironmentVariables;
use aliased 'Oberth::Prototype::Runnable';

has msystem => (
	is => 'ro',
	default => sub { 'MINGW64' },
);

lazy msystem_base_path => method() {
	my $msystem_lc = lc $self->msystem;
	File::Spec->catfile( $self->msys2_dir, $msystem_lc );
};

lazy msystem_bin_path => method() {
	File::Spec->catfile( $self->msystem_base_path, qw(bin) );
};

has msys2_dir => (
	is => 'ro',
	default => sub {
		qq|C:\\msys64|;
	},
);

lazy perl_path => method() {
	File::Spec->catfile( $self->msystem_bin_path, qw(perl.exe) );
};

lazy paths => method() {
	my $msystem_lc = lc $self->msystem;
	[
		map { $self->msys2_dir . '\\' . $_ } (
			qq|${msystem_lc}\\bin|,
			qq|${msystem_lc}\\bin\\core_perl|,
			qq|usr\\bin|,
		)
	];
};

lazy environment => method() {
	my $env = Oberth::Prototype::EnvironmentVariables->new;

	$env->set_string('MSYSTEM', $self->msystem );

	$env->prepend_path_list('PATH', $self->paths );

	# Skip font cache generation (for fontconfig):
	# <https://github.com/Alexpux/MINGW-packages/commit/fdea2f9>
	# <https://github.com/Homebrew/homebrew-core/issues/10920>
	$env->set_string('MSYS2_FC_CACHE_SKIP', 1 );

	# OpenSSL
	delete $ENV{OPENSSL_CONF};
	$env->set_string('OPENSSL_PREFIX', $self->msystem_base_path);

	use FindBin;
	$env->set_string('PERL5OPT', "-I@{[ File::Spec->catfile( $FindBin::Bin, '..', qw{project-renard devops script mswin} ) ]} -MEUMMnosearch");

	$env;
};

method _pre_run() {
}

method perl_bin_paths() {
	my $msystem_lc = lc $self->msystem;
	local $ENV{PATH} = join ";", @{ $self->paths }, $ENV{PATH};

	chomp( my $site_bin   = `perl -MConfig -E "say \$Config{sitebin}"` );
	chomp( my $vendor_bin = `perl -MConfig -E "say \$Config{vendorbin}"` );
	my @perl_bins = ( $site_bin, $vendor_bin, '/mingw64/bin/core_perl' );
	my @perl_bins_w;
	for my $path_orig ( @perl_bins ) {
		chomp(my $path = `cygpath -w '$path_orig'`);
		push @perl_bins_w, $path;
	}
	join ";", @perl_bins_w;
}

method cygpath($path_orig) {
	local $ENV{PATH} = join ";", @{ $self->paths }, $ENV{PATH};
	chomp(my $path = `cygpath -u $path_orig`);

	$path;
}

method _install() {
	# Appveyor under MSYS2/MinGW64
	$self->pacman('pacman-mirrors');
	$self->pacman('git');

	# For the `--ask 20` option, see
	# <https://github.com/Alexpux/MSYS2-packages/issues/1141>.
	#
	# Otherwise the message
	#
	#     :: msys2-runtime and catgets are in conflict. Remove catgets? [y/N]
	#
	# is displayed when trying to update followed by an exit rather
	# than selecting yes.

	# Update
	$self->runner->system(
		Runnable->new(
			command => [ qw(pacman -Syu --ask 20 --noconfirm) ],
			environment => $self->environment,
		)
	);

	# build tools
	$self->pacman(qw(mingw-w64-x86_64-make mingw-w64-x86_64-toolchain autoconf automake libtool make patch mingw-w64-x86_64-libtool));

	# OpenSSL
	$self->pacman(qw(mingw-w64-x86_64-openssl));

	# There is not a corresponding cc for the mingw64 gcc. So we copy it in place.
	$self->run(qw(cp -pv /mingw64/bin/gcc /mingw64/bin/cc));
	$self->run(qw(cp -pv /mingw64/bin/mingw32-make /mingw64/bin/gmake));

	# Workaround for Data::UUID installation problem.
	# See <https://github.com/rjbs/Data-UUID/issues/24>.
	mkdir 'C:\tmp';

	$self->_install_perl;
}

method _install_perl() {
	$self->pacman(qw(mingw-w64-x86_64-perl));
	$self->build_perl->script( 'pl2bat', $self->build_perl->which_script('pl2bat') );
	{
		local $ENV{PERL_MM_USE_DEFAULT} = 1;
		$self->build_perl->script( qw(cpan App::cpanminus) );
	}
	$self->build_perl->script( qw(cpanm --notest App::cpm ExtUtils::MakeMaker Module::Build App::pmuninstall) );
	$self->build_perl->script( qw(cpanm --notest Win32::Process IO::Socket::SSL) );
}

method run( @command ) {
	$self->runner->system( Runnable->new(
		command => [ @command ],
		environment => $self->environment
	));
}

method pacman(@packages) {
	return unless @packages;
	$self->runner->system(
		Runnable->new(
			command => [ qw(pacman -S --needed --noconfirm), @packages ],
			environment => $self->environment,
		)
	);
}

method install_packages($repo) {
	my @packages = @{ $repo->msys2_mingw64_get_packages };
	say STDERR "Installing repo native deps";
	$self->pacman(@packages);
}

with qw(
	Oberth::Prototype::System::Role::Config
	Oberth::Prototype::System::Role::DefaultRunner
	Oberth::Prototype::System::Role::Perl
);

1;
