use Modern::Perl;
package Oberth::Prototype::Runner::Default;
# ABSTRACT: Default runner

use Mu;
use Oberth::Manoeuvre::Common::Setup;
use IPC::System::Simple ();
use Capture::Tiny ();

method system( $runnable ) {
	if( $> != 0 && $runnable->admin_privilege ) {
		warn "Not running command (requires admin privilege): @{ $runnable->command }";
		return;
	}

	local %ENV = %{ $runnable->environment->environment_hash };
	use autodie qw(:system);
	system( @{ $runnable->command } );
}

method capture( $runnable ) {
	Capture::Tiny::capture(sub {
		$self->system( $runnable );
	})
}

1;
