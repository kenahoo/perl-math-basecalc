#! perl

use strict;
use warnings;
use Config;
use Test::More;

eval "use Math::BigInt";
if ($@) {
  plan skip_all => "Requires Math::BigInt";
} elsif ($Config{ivsize} != 8) {
  plan skip_all => "Requires 64-bit integers";
} else {
  plan tests => 64;
}

use_ok('Math::BaseCalc');

my $calc16 = new Math::BaseCalc(digits=>'hex');
my $calc10 = new Math::BaseCalc(digits=>[0..9]);
my $calc36 = new Math::BaseCalc(digits=>[0..9,'a'..'z']);

# Native integers above 2**63-1 (unsigned range)
{
  my @cases = (
    [ '9223372036854775807',  '7fffffffffffffff', '1y2p0ij32e8e7' ],
    [ '9223372036854775808',  '8000000000000000', '1y2p0ij32e8e8' ],
    [ '18446744073709551615', 'ffffffffffffffff', '3w5e11264sgsf' ],
  );
  foreach my $case (@cases) {
    my ($dec, $hex, $b36) = @$case;
    my $num = $dec + 0;
    is($calc16->to_base($num), $hex, "to_base($dec) in hex");
    is($calc36->to_base($num), $b36, "to_base($dec) in base 36");
    is($calc10->to_base($num), $dec, "to_base($dec) in base 10");

    my $back = $calc16->from_base($hex);
    is($back, $dec, "from_base($hex)");
    ok(!ref $back, "from_base($hex) is a native number");
    is($calc36->from_base($b36), $dec, "from_base($b36)");
  }
}

# Beyond the native range
{
  my @cases = (
    [ '18446744073709551616', '10000000000000000' ],
    [ '18446744073709551617', '10000000000000001' ],
    [ '18446744073709552639', '100000000000003ff' ],
    [ '36893488147419103233', '20000000000000001' ],
    [ '340282366920938463463374607431768211457', '100000000000000000000000000000001' ],
  );
  foreach my $case (@cases) {
    my ($dec, $hex) = @$case;
    is($calc16->to_base($dec), $hex, "to_base('$dec') from a string");
    is($calc16->to_base(Math::BigInt->new($dec)), $hex, "to_base($dec) from a Math::BigInt");
    is($calc16->to_base("-$dec"), "-$hex", "to_base('-$dec') from a string");

    my $back = $calc16->from_base($hex);
    isa_ok($back, 'Math::BigInt', "from_base($hex)");
    is("$back", $dec, "from_base($hex) is exact");
    is($calc16->from_base("-$hex"), "-$dec", "from_base(-$hex) is exact");
  }
}

# Floats are converted according to their exact value
is($calc16->to_base(2**70), '400000000000000000', "to_base(2**70)");
is($calc10->to_base(1e20), '100000000000000000000', "to_base(1e20)");

# Negative numbers: the native range only reaches -2**63
{
  my @cases = (
    [ '-9223372036854775807',  '-7fffffffffffffff', 0 ],
    [ '-9223372036854775808',  '-8000000000000000', 0 ],
    [ '-9223372036854775809',  '-8000000000000001', 1 ],
    [ '-18446744073709551615', '-ffffffffffffffff', 1 ],
  );
  foreach my $case (@cases) {
    my ($dec, $hex, $big) = @$case;
    my $back = $calc16->from_base($hex);
    is("$back", $dec, "from_base($hex) is exact");
    is(ref $back, $big ? 'Math::BigInt' : '', "from_base($hex) is " . ($big ? 'a Math::BigInt' : 'a native number'));
    is($calc10->from_base($dec), $dec, "from_base($dec) in base 10 is exact");
  }
}

is($calc16->to_base(-0.5), '0', "to_base(-0.5) has no minus sign");
