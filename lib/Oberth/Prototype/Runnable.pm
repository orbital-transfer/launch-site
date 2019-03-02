use Modern::Perl;
package Oberth::Prototype::Runnable;
# ABSTRACT: Base for runnable command

use Mu;
use Oberth::Manoeuvre::Common::Setup;
use Oberth::Manoeuvre::Common::Types qw(ArrayRef Str InstanceOf Bool);

use Oberth::Prototype::EnvironmentVariables;

has command => (
	is => 'ro',
	isa => ArrayRef[Str],
	required => 1,
);

has environment => (
	is => 'ro',
	isa => InstanceOf['Oberth::Prototype::EnvironmentVariables'],
	default => sub { Oberth::Prototype::EnvironmentVariables->new },
);

has admin_privilege => (
	is => 'ro',
	isa => Bool,
	default => sub { 0 },
);

1;
