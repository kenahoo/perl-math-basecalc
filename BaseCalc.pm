package Math::BaseCalc;

use strict;
use Carp;
use vars qw($VERSION);

# I think I can control this.
$VERSION = sprintf "%d.%03d", q$Revision: 1.7 $ =~ /: (\d+).(\d+)/;

sub new {
  my ($pack, %opts) = @_;
  my $self = bless {}, $pack;
  $self->digits($opts{digits});
  return $self;
}

sub digits {
  my $self = shift;
  if (@_) {
    # Set the value

    if (ref $_[0]) {
      $self->{digits} = [ @{ shift() } ];
    } else {
      my $name = shift;
      my %digitsets = $self->_digitsets;
      croak "Unrecognized digit set '$name'" unless exists $digitsets{$name};
      $self->{digits} = $digitsets{$name};
    }

    # Build the translation table back to numbers
    @{$self->{trans}}{@{$self->{digits}}} = 0..$#{$self->{digits}};

  }
  return @{$self->{digits}};
}


sub _digitsets {
  return (
	  'bin' => [0,1],
	  'hex' => [0..9,'a'..'f'],
	  'HEX' => [0..9,'A'..'F'],
	  'oct' => [0..7],
	  '64'  => ['A'..'Z','a'..'z',0..9,'+','/'],
	  '62'  => [0..9,'a'..'z','A'..'Z'],
	 );
}

sub from_base {
  my $self = shift;
  my $str = reverse shift;

  return -1*$self->from_base(substr($str,1)) if substr($str,0,1) eq '-'; # Handle negative numbers
  
  my $dignum = @{$self->{digits}};
  
  my $result = 0;
  while (length $str) {
    $result *= $dignum;
    $result += $self->{trans}{chop $str};
  }
  return $result;
}

sub to_base {
  my ($self,$num) = @_;
  return '-'.$self->to_base(-1*$num) if $num<0; # Handle negative numbers
  
  my $dignum = @{$self->{digits}};
  
  use integer;
  my $result = '';
  while ($num>0) {
    substr($result,0,0) = $self->{digits}[ $num % $dignum ];
    $num /= $dignum;
  }
  return length $result ? $result : $self->{digits}[0];
}


1;
__END__


=head1 NAME

Math::BaseCalc - Convert numbers between various bases

=head1 SYNOPSIS

  use Math::BaseCalc;

  my $calc = new Math::BaseCalc(digits => [0,1]); #Binary
  my $bin_string = $calc->to_base(65); # Convert 465 to binary

  $calc->digits('oct'); # Octal
  my $number = $calc->from_base('1574'); # Convert octal 1574 to decimal

=head1 DESCRIPTION

This module facilitates the conversion of numbers between various
number bases.  You may define your own digit sets, or use any of
several predefined digit sets.

The to_base() and from_base() methods convert between Perl numbers and
strings which represent these numbers in other bases.  For instance,
if you're using the binary digit set [0,1], $calc->to_base(5) will
return the string "101".  $calc->from_base("101") will return the
number 5.

To convert between, say, base 7 and base 36, use the 2-step process
of first converting to a Perl number, then to the desired base for the
result:

 $calc7  = new Math::BaseCalc(digits=>[0..7]);
 $calc36 = new Math::BaseCalc(digits=>[0..9,'a'..'z'];
 
 $in_base_36 = $calc36->to_base( $calc7->from_base('3506') );

If you just need to handle regular octal & hexdecimal strings, you
probably don't need this module.  See the sprintf(), oct(), and hex()
Perl functions.

=head1 METHODS

=over 4

=item * new Math::BaseCalc

=item * new Math::BaseCalc(digits=>...)

Create a new base calculator.  You may specify the digit set to use,
by either giving the digits in a list reference (in increasing order,
with the 'zero' character first in the list) or by specifying the name
of one of the predefined digit sets (see the digit() method below).

=item * $calc->to_base(NUMBER)

Converts a number to a string representing that number in the
associated base.  Currently only handles integers.

=item * $calc->from_base(STRING)

Converts a string representing a number in the associated base to a
Perl integer.  Currently only handles integers.  The behavior when fed
strings with characters not in $calc's digit set is currently
undefined.

=item * $calc->digits

=item * $calc->digits(...)

Get/set the current digit set of the calculator.  With no arguments,
simply returns a list of the characters that make up the current digit
set.  To change the current digit set, pass a list reference
containing the new digits, or the name of a predefined digit set.
Currently the predefined digit sets are:

       bin => [0,1],
       hex => [0..9,'a'..'f'],
       HEX => [0..9,'A'..'F'],
       oct => [0..7],
       64  => ['A'..'Z','a'..'z',0..9,'+','/'],
       62  => [0..9,'a'..'z','A'..'Z'],
 
 Examples:
  $calc->digits('bin');
  $calc->digits([0..7]);
  $calc->digits([qw(w a l d o)]);

If any of your "digits" has more than one character, the behavior is
currently undefined.

=back

=head1 QUESTIONS

The '64' digit set is meant to be useful for Base64 encoding.  I took
it from the MIME::Base64.pm module.  Does it look right?  It's sure in
a strange order.

=head1 AUTHOR

Ken Williams, ken@forum.swarthmore.edu

=head1 COPYRIGHT

This is free software in the colloquial nice-guy sense of the word.
Copyright (c) 1999, Ken Williams.  You may redistribute and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut
