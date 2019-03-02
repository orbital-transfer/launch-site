use Modern::Perl;
package Oberth::Prototype::System::Role::DefaultRunner;
# ABSTRACT: Default runner

use Mu::Role;
use Oberth::Manoeuvre::Common::Setup;

use Oberth::Prototype::Runner::Default;

lazy runner => method() {
	Oberth::Prototype::Runner::Default->new;
};

1;
