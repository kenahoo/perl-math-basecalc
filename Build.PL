
use Module::Build;


my $build = Module::Build->new
  (
   module_name => 'Math::BaseCalc',
   license => 'perl',
   build_requires => {
		      'Test::More' => 0,
		     },
   create_makefile_pl => 'traditional',
   create_readme => 1,
   sign => 1,
  );

$build->create_build_script;
