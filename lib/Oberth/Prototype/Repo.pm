use Modern::Perl;
package Oberth::Prototype::Repo;
# ABSTRACT: Represent the top level of a code base repo

use Mu;

use Oberth::Common::Setup;
use Oberth::Common::Types qw(AbsDir);

has directory => (
	is => 'ro',
	required => 1,
	coerce => 1,
	isa => AbsDir,
);

has config => (
	is => 'ro',
	required => 1,
);

1;
