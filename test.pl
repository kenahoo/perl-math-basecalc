# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}
use Math::BaseCalc;
$loaded = 1;
&report(1);

######################### End of black magic.

my $calc = new Math::BaseCalc(digits=>[0,1]);
&report($calc);

my $result = $calc->from_base('01101');
&report($result == 13, "$result\n");

$calc->digits('bin');
$result = $calc->from_base('1101');
&report($result == 13, "$result\n");

$result = $calc->to_base(13);
&report($result eq '1101', "$result\n");

$calc->digits('hex');
$result = $calc->to_base(46);
&report($result eq '2e', "$result\n");

$calc->digits([qw(i  a m  v e r y  p u n k)]);
$result = $calc->to_base(13933);
&report($result eq 'krap', "$result\n");

$calc->digits('hex');
$result = $calc->to_base('-17');
&report($result eq '-11', "$result\n");

$calc->digits('hex');
$result = $calc->from_base('-11');
&report($result eq '-17', "$result\n");

$calc->digits('hex');
$result = $calc->from_base('-11.05');
&report($result eq '-17.01953125', "$result\n");

$calc->digits([0..6]);
$result = $calc->from_base('0.1');
&report($result eq (1/7), "$result\n");

# Test large numbers
$calc->digits('hex');
my $r1 = $calc->to_base(2**55 + 5);
$result = $calc->from_base($calc->to_base(2**55 + 5));
#warn "res: $r1, $result";
&report($result eq 2**55 + 5, "$result\n");

{
  $calc->digits('bin');
  my $first  = $calc->from_base('1110111');
  my $second = $calc->from_base('1010110');
  my $third = $calc->to_base($first * $second);
  &report($third eq '10011111111010', "$third\n");
}

sub report {
  my $bad = !shift;
  print "not " x $bad;
  print "ok ", ++$TESTNUM, "\n";
  print @_ if $ENV{TEST_VERBOSE} and $bad;
}


