use strict;
use warnings;
package Oberth::Prototype::Command::Bootstrap;
# ABSTRACT: Bootstrap a repo

use feature 'say';
use IPC::Open3;
use File::Spec;
use File::Find;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Glob;
use Config;
use Env qw(@PATH @PERL5LIB);
use constant COMMANDS => (
	'setup' => \&run_setup,
	'generate-cpanfile' => \&run_generate_cpanfile,
	'install-deps-from-cpanfile' => \&run_install_deps_from_cpanfile,
);

sub new {
	my ($package) = @_;

	my $dir;
	my $command;

	my $commands_re = qr/^(@{[ join("|", keys %{ {COMMANDS()} }) ]})$/;

	while(@ARGV) {
		my $arg = shift @ARGV;
		if( $arg eq '--dir' ) {
			$dir = shift @ARGV;
		} elsif( $arg =~ $commands_re ) {
			$command = $arg;
		}
	}

	die "need command: $commands_re" unless $command;

	$dir = tempdir( CLEANUP => 1 ) unless $dir;

	my $bin_dir = File::Spec->catfile($dir, qw(bin));
	make_path $bin_dir;

	unshift @PATH, $bin_dir;

	my $lib_dir = File::Spec->catfile($dir, qw(lib));
	make_path $lib_dir;

	unshift @PERL5LIB, File::Spec->catfile( $dir, qw(lib perl5) );
	unshift @PERL5LIB, File::Spec->catfile( $dir, qw(lib perl5), $Config{archname});

	bless {
		command => $command,
		dir => $dir,
		bin_dir => $bin_dir,
		lib_dir => $lib_dir,
	}, $package;
}

sub run_setup {
	my ($self) = @_;

	$self->install_self_contained_cpm unless $self->has_cpm;

	$self->_cpm(
		qw(App::cpanminus),
	) unless $self->has_cpanm;

	$self->_cpanm(
		#qw(Perl::PrereqScanner::Lite),
		#qw(Perl::PrereqScanner),
		qw(App::scan_prereqs_cpanfile),
	);
}

sub _cpm {
	my ($self, @args) = @_;

	system( qw(cpm), qw(install),
		qw(--verbose),
		qw(-L), $self->{dir},
		@args,
	);
}

sub _cpanm {
	my ($self, @args) = @_;

	system( qw(cpanm),
		qw(-nq),
		qw(-L), $self->{dir},
		@args,
	);
}

sub create_cpanfile_in_directory {
	my ($self, $dir) = @_;

	my ($wtr, $rdr, $err);

	my $cpanfile = IO::File->new(File::Spec->catfile($dir, 'cpanfile'), 'w');

	my $pid = open3($wtr, $rdr, $err,
		qw(scan-prereqs-cpanfile),
		qq(--ignore=@{[ $self->{dir} ]},vendor),
		"--dir=$dir",
	);

	close $wtr;
	while(<$rdr>) {
		next if /Oberth/;
		print $cpanfile $_;
	}
	waitpid( $pid, 0 );

	my $child_exit_status = $? >> 8;
}

sub run_generate_cpanfile {
	my ($self) = @_;

	$self->create_cpanfile_in_directory('.');

	my @dirs = $self->get_vendor_dirs;
	for my $vendor_dir (@dirs) {
		$self->create_cpanfile_in_directory($vendor_dir);
	}
}

sub get_vendor_dirs {
	my ($self) = @_;

	my @dirs = grep { -d } <vendor/*>;
}

sub _install_cpanfile {
	my ($self, $cpanfile) = @_;

	$self->_cpm(
		"--cpanfile=$cpanfile"
	);

	$self->_cpanm(
		qw(--installdeps .),
		qw(--cpanfile), $cpanfile,
	);
}

sub run_install_deps_from_cpanfile {
	my ($self) = @_;

	$self->_install_cpanfile(File::Spec->catfile('.', 'cpanfile'));

	my @dirs = $self->get_vendor_dirs;
	for my $vendor_dir (@dirs) {
		$self->_install_cpanfile(File::Spec->catfile($vendor_dir, 'cpanfile'));
	}
}

sub run {
	my ($self) = @_;

	my $cmd = { COMMANDS }->{ $self->{command} };

	die "command invalid: @{[ $self->{command} ]}" unless $cmd;

	$self->$cmd();
}

sub get_exit_status {
	my ($self, $command, @args) = @_;
	my ($wtr, $rdr, $err);
	my $child_exit_status = 1;
	eval {
		my $pid = open3($wtr, $rdr, $err,
			$command, @args);

		close $wtr;
		print while(<$rdr>);

		waitpid( $pid, 0 );
		$child_exit_status = $? >> 8;
	};
	return $child_exit_status;
}

sub has_cpan {
	my ($self) = @_;
	return 0 == $self->get_exit_status(qw(cpan -v));
}

sub has_cpanm {
	my ($self) = @_;
	return 0 == $self->get_exit_status(qw(cpanm -V));
}

sub has_cpm {
	my ($self) = @_;
	return 0 == $self->get_exit_status(qw(cpm --version));
}

sub install_self_contained_cpm {
	my ($self) = @_;

	$self->{cpm} = File::Spec->catfile( $self->{bin_dir}, qw(cpm) );

	0 == system( qw(curl -sL --compressed https://git.io/cpm -o), $self->{cpm} ) or die "Could not download cpm: $!";
	chmod 0755, $self->{cpm};
	die "Could not install cpm: $!" unless $self->has_cpm;
}

1;
