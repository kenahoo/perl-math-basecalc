# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
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
&report($result == 'krap', "$result\n");

sub report {
  my $bad = !shift;
  print "not " x $bad;
  print "ok ", ++$TESTNUM, "\n";
  print @_ if $ENV{TEST_VERBOSE} and $bad;
}


