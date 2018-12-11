use Modern::Perl;
package Oberth::Prototype::Repo::Role::CpanfileGit;
# ABSTRACT: Role for cpanfile Git datai

use Mu::Role;

use Oberth::Manoeuvre::Common::Setup;

use File::Spec;
use Module::CPANfile;

lazy cpanfile_git_data => method() {
	my $data = {};
	my $cpanfile_git_path = File::Spec->catfile($self->directory, qw(maint cpanfile-git));
	if ( -r $cpanfile_git_path  ) {
		my $m = Module::CPANfile->load($cpanfile_git_path);
		$data = +{ map { $_ => $m->options_for_module($_) }
			$m->prereqs->merged_requirements->required_modules };
	}

	return $data;
};

1;
