#! perl

use strict;
use warnings;
use Test::More tests => (6 * 42) + 1;
my $class = 'Math::BaseCalc';
use_ok($class);

my @calcs;
push(@calcs, new_ok( $class => [ digits=>[ '0', '&' ] ]) );
push(@calcs, new_ok( $class => [ digits=>[ '0', '-' ] ]) );
push(@calcs, new_ok( $class => [ digits=>[ '0', '.' ] ]) );
push(@calcs, new_ok( $class => [ digits=>[ '0', '&' ], neg_char => '~', radix_char => ',' ]) );
push(@calcs, new_ok( $class => [ digits=>[ '0', '-' ], neg_char => '~', radix_char => ',' ]) );
push(@calcs, new_ok( $class => [ digits=>[ '0', '.' ], neg_char => '~', radix_char => ',' ]) );

for my $calcX ( @calcs ) {
  for my $s (-20..20) {
    my $source = $s / 2;
    my $in_base_X  = $calcX->to_base( $source );
    my $in_base_10 = $calcX->from_base( $in_base_X );
	
    # expected result may have changed based on lack of neg/radix
    my $expect = $source;
    $expect = abs($expect) unless ($calcX->{neg_char});
    $expect = int($expect) unless ($calcX->{radix_char});
   
    is $in_base_10, $expect, "from( to ( $source ) == $in_base_X --> $expect (using ".join(',', $calcX->digits).")";
  }
}
