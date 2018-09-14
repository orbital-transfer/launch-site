use Modern::Perl;
package Oberth::Prototype::Config;
# ABSTRACT: A configuration for 

use Mu;

use Oberth::Common::Setup;
use FindBin;

has build_tools_dir => (
	is => 'ro',
	required => 1,
);

has lib_dir => (
	is => 'ro',
	default => sub { 'local' },
);

has external_dir => (
	is => 'ro',
	default => sub {
		File::Spec->catfile( $FindBin::Bin, '..', qw(external));
	},
);

1;
