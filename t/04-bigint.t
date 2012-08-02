use Test::More;
use strict;
use warnings;

eval "use Math::BigInt";
if ($@) {
  plan skip_all => "Requires Math::BigInt";
} else {
  plan tests => 6;
}

use_ok('Math::BaseCalc');

my $bignum = new_ok('Math::BigInt', [2]) ** 120 + 7;

roundtrip36( $bignum, '24q5bylddqo566k7npiubn5z' );

sub roundtrip36 {
  my ($num, $expect) = @_;

  my $calc36 = new_ok('Math::BaseCalc' => [digits=>[0..9,'a'..'z']]);
  my $base36 = $calc36->to_base($num);
  is($base36, $expect, "to_base has done proper conversion of $num");
  my $num2 = $calc36->from_base($base36);
  is($num2, $num->bstr, "$num has roundtripped");
  $num2 = $calc36->from_base($expect);
  is($num2, $num->bstr, "from_base correct for $expect ($num)");
}
