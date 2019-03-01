use Modern::Perl;
package Oberth::Prototype::Runnable;
# ABSTRACT: Base for runnable command

use Mu;
use Oberth::Manoeuvre::Common::Setup;
use Oberth::Manoeuvre::Common::Types qw(ArrayRef Str HashRef Bool);

has command => (
	is => 'ro',
	isa => ArrayRef[Str],
	required => 1,
);

has environment => (
	is => 'ro',
	isa => HashRef,
	default => sub { +{} },
);

has admin_privilege => (
	is => 'ro',
	isa => Bool,
	default => sub { 0 },
);

1;
