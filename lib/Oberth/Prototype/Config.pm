use Modern::Perl;
package Oberth::Prototype::Config;
# ABSTRACT: A configuration for 

use Mu;

use Oberth::Common::Setup;
use Path::Tiny;
use FindBin;
use Env qw($OBERTH_GLOBAL_INSTALL);

has build_tools_dir => (
	is => 'ro',
	required => 1,
);

has lib_dir => (
	is => 'ro',
	default => sub { path('local')->absolute },
);

has external_dir => (
	is => 'ro',
	default => sub {
		File::Spec->catfile( '..', qw(external) );
	},
);

has platform => (
	is => 'ro',
	required => 1,
);

has cpan_global_install => (
	is => 'ro',
	default => sub {
		my $global = $OBERTH_GLOBAL_INSTALL // 0;
	},
);

1;
