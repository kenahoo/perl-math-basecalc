package Math::BaseCalc;

use strict;
use Carp;
use Math::BigInt;
use Math::BigFloat;
use vars qw($VERSION);
$VERSION = '1.2';

# configure some basic big number stuff
Math::BigInt  ->config({
   upgrade    => 'Math::BigFloat',
   round_mode => 'common',
   trap_nan   => 1,
   trap_inf   => 1,
});
Math::BigFloat->config({
   round_mode => 'common',
   trap_nan   => 1,
   trap_inf   => 1,
});

sub new {
  my ($pack, %opts) = @_;
  my $self = bless {}, $pack;
  $self->{neg_char}   = $opts{neg_char}   || '-';
  $self->{radix_char} = $opts{radix_char} || '.';
  $opts{digits} = $_[1] if (@_ == 2);
  $self->digits($opts{digits});
  return $self;
}

sub digits {
  my $self = shift;
  return @{$self->{digits}} unless (@_);

  # Set the value
  if (ref $_[0] eq 'ARRAY') {
    $self->{digits} = [ @{ shift() } ];
    delete $self->{digitset_name};
  } else {
    my $name = shift;
    my %digitsets = $self->_digitsets;
    croak "Unrecognized digit set '$name'" unless exists $digitsets{$name};
    $self->{digits} = $digitsets{$name};
    $self->{digitset_name} = $name;
  }
  $self->{neg_char}   = '' if (grep { $_ eq $self->{neg_char}   } @{$self->{digits}});
  $self->{radix_char} = '' if (grep { $_ eq $self->{radix_char} } @{$self->{digits}});
  $self->{digit_strength} = log(scalar @{$self->{digits}}) / log(10);
  
  # Build the translation table back to numbers
  delete $self->{trans};
  @{$self->{trans}}{@{$self->{digits}}} = 0..$#{$self->{digits}};

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
  my ($self, $str) = @_;
  my ($nc, $fc) = @$self{qw(neg_char radix_char)};
  return -1*$self->from_base($str) if $nc && $str =~ s/^\Q$nc\E//; # Handle negative numbers

  # number clean up + decimal checks
  my $base = @{$self->{digits}};
  my $zero = $self->{digits}[0];
  my $is_dec = ($fc && $str =~ /\Q$fc\E/);
  $str =~ s/^\Q$zero\E+//;
  $str =~ s/\Q$zero\E+$// if ($is_dec);

  # upgrade doesn't work as well as it should...
  ## no critic (TestingAndDebugging::ProhibitNoStrict)
  no strict 'subs';
  my $big_class = $is_dec ? Math::BigFloat : Math::BigInt;
  use strict 'subs';
  
  # num of digits + big number support
  my $poten_digits = int(length($str) * $self->{digit_strength}) + 16;
  $big_class->accuracy($poten_digits + 16);
  my $result = $big_class->new(0);

  # short-circuits
  unless ($is_dec || !$self->{digitset_name}) {
    $result = $result->from_hex(lc "0x$str") if ($self->{digitset_name} =~ /^hex$/i);
    $result = $result->from_bin(   "0b$str") if ($self->{digitset_name} eq 'bin');
    $result = $result->from_oct(lc  "0$str") if ($self->{digitset_name} eq 'oct');
  }
  
  if ($result == 0) {
    # num of digits (power)
    my $i = 0;
    $i = length($str)- 1;
    # decimal digits (yes, this removes the radix point, but $i captures the "digit location" information.)
    $i = length($1)  - 1 if ($fc && $str =~ s/^(.*)\Q$fc\E(.*)$/$1$2/);

    while ( $str =~ s/^(.)// ) {
      my $v = $self->{trans}{$1};
      croak "Invalid character $1 in string!" unless defined $v;
      
      my $exp = $big_class->new($base);
      $result = $exp->bpow($i)->bmul($v)->badd($result);
      $i--;  # may go into the negative for non-ints
    }
  }

  # never lose the accuracy
  my $rscalar = $result->numify();
  my $rstring = $result->bstr();
  $rstring =~ s/0+$// if ($rstring =~ /\./);
  # (the user can choose to put the string in a Math object if s/he so wishes)
  return $rstring eq ($rscalar + 0 . '') ? $result->numify() : $result->bstr();
}

sub to_base {
  my ($self,$num) = @_;
  return $self->{neg_char}.$self->to_base(-1*$num) if $num<0; # Handle negative numbers

  # decimal checks
  my $base = scalar @{$self->{digits}};
  $num = int($num) unless $self->{radix_char};  # can't use floats, so truncate
  my $is_dec = ($num =~ /\./) ? 1 : 0;
  my $zero = $self->{digits}[0];

  # upgrade doesn't work as well as it should...
  ## no critic (TestingAndDebugging::ProhibitNoStrict)
  no strict 'subs';
  my $big_class = $is_dec ? Math::BigFloat : Math::BigInt;
  use strict 'subs';

  # num of digits + big number support
  my $poten_digits = length($num);
  $big_class->accuracy($poten_digits + 16);
  $num = $big_class->new($num);
  
  # short-circuits
  return $zero if ($num == 0);  # this confuses log, so let's just get rid of this quick
  unless ($is_dec || !$self->{digitset_name}) {
     return substr(lc $num->as_hex(), 2) if ($self->{digitset_name} eq 'hex');
     return substr(uc $num->as_hex(), 2) if ($self->{digitset_name} eq 'HEX');
     return substr(   $num->as_bin(), 2) if ($self->{digitset_name} eq 'bin');
     return substr(   $num->as_oct(), 1) if ($self->{digitset_name} eq 'oct');
  }

  # get the largest power of Z (the highest digit)
  my $i = $num->copy()->blog(
    $base,
    int($num->length() / 9) + 2  # (an accuracy that is a little over the potential # of integer digits within log)  
  )->bfloor()->numify();
  
  my $result = '';
  # BigFloat's accuracy should counter this, but the $i check is
  # to make sure we don't get into an irrational/cyclic number loop
  while (($num != 0 || $i >= 0) && $i > -1024) {
    my $exp = $big_class->new($base)->bpow($i);
    my $v   = $num->copy()->bdiv($exp)->bfloor();
    $num   -= $v * $exp;  # this method is safer for fractionals
    
    $result .= $self->{radix_char} if ($i == -1);  # decimal point
    $result .= $self->{digits}[$v];
    
    $i--;  # may go into the negative for non-ints
  }

  # Final cleanup
  return $zero unless length $result;
  
  $result =~ s/^\Q$zero\E+//;
  $result =~ s/\Q$zero\E+$// if ($is_dec);
  
  return $result;
}

1;
__END__


=head1 NAME

Math::BaseCalc - Convert numbers between various bases

=head1 VERSION

version 1.2

=head1 SYNOPSIS

  use Math::BaseCalc;

  my $calc = new Math::BaseCalc(digits => [0,1]); #Binary
  my $bin_string = $calc->to_base(465); # Convert 465 to binary

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

 $calc7  = new Math::BaseCalc(digits=>[0..6]);
 $calc36 = new Math::BaseCalc(digits=>[0..9,'a'..'z']);

 $in_base_36 = $calc36->to_base( $calc7->from_base('3506') );

If you just need to handle regular octal & hexdecimal strings, you
probably don't need this module.  See the sprintf(), oct(), and hex()
Perl functions.  (In fact, this module will short-circuit any conversions
to/from standard binary, octal, and hex, and use those functions instead,
as their internal code is much faster.)

=head1 METHODS

=over 4

=item * new Math::BaseCalc

=item * new Math::BaseCalc(digits=>...)

Create a new base calculator.  You may specify the digit set to use,
by either giving the digits in a list reference (in increasing order,
with the 'zero' character first in the list) or by specifying the name
of one of the predefined digit sets (see the digit() method below).

=item * new Math::BaseCalc(digits=>..., neg_char=>CHAR, radix_char=>CHAR)

If your digit set includes the characters C<-> or C<.>, you can specify
a different negative character and radix point character (decimal mark),
so that they can be used to detect negative and fractional numbers.

If the negative or radix characters are the same as a character in the
digit set, either by using a dash/period in your set without changing
the defaults or by explicitly using the same character in both, then 
that number type will be disabled.  For example:

  # negative: - and radix: .
  new Math::BaseCalc(digits => [0,1]);
  # the following cannot represent negative numbers
  new Math::BaseCalc(digits => [0,1,'-']); 
  # nor can this; neg_char will be reset to ''
  new Math::BaseCalc(digits => [0,1], neg_char => 1); 
  
  # cannot use fractional numbers
  # any fractionals will be truncated via int() prior to conversion
  new Math::BaseCalc(digits => [0,1,'.']); 

=item * $calc->to_base(NUMBER)

Converts a number to a string representing that number in the
associated base.

If C<NUMBER> is a C<Math::BigInt> object, C<to_base()> will still work
fine and give you an exact result string.  In fact, Math::Big* is loaded in
the background, so big numbers are fully supported.

As of v1.2, C<to_base()> will give you fractional results if passed a
fractional number, provided that the radix point character is still
available to use.

=item * $calc->from_base(STRING)

Converts a string representing a number in the associated base to a
Perl number.  Unlike versions prior to v1.2, C<from_base()> will fatally
die if given a character not in $calc's digit set.  Hence, if this is a
problem, you should clean your strings (including whitespace) prior to
conversion.

"Fractional" strings will be converted to fractional numbers, provided
that the radix point character is still available to use.  Negative
strings are supported, provided that the negative character is still
available to use.

Large numbers are also fully supported, as of v1.2.  The exact type of
scalar returned depends on the size of the number.  If Perl cannot safely
represent the exact number, a string scalar is returned instead.  Note that
C<from_base()> will never return an object, such as a Math::BigInt object,
even though it's used internally.  This gives you the option to use whatever
"big number" library you so choose by passing the string to that object.

This also means that the string scalar is "fragile" if any sort of numerical
context is coaxed into it.  For example:

  use feature 'say';
  my $calc = Math::BaseCalc->new(62);  # Base62 -- see digits() below
  my $num  = $calc->from_base('ThisWillBeALargeNumber');

  say $num;        # 1189195843250277485668721077169519303389
  say ($num + 0);  # 1.18919584325028e+039
  say int($num);   # 1.18919584325028e+039
  say ($num / 2);  # 5.94597921625139e+038
  
  $num = Math::BigInt->new($num);  # now $num is protected from truncation
  say $num;        # 1189195843250277485668721077169519303389
  say ($num + 0);  # 1189195843250277485668721077169519303389
  say int($num);   # 1189195843250277485668721077169519303389
  say ($num / 2);  # 594597921625138742834360538584759651694.5
  
  # this also works
  use bigint;  # or bignum
  say ($num + 0);
  # in this case, 0 is a Math::BigInt(-ish) object and $num is auto-converted
  # to one as well

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
       # the above are short-circuited to use sprintf/oct       
       64  => ['A'..'Z','a'..'z',0..9,'+','/'],
       62  => [0..9,'a'..'z','A'..'Z'],

 Examples:
  $calc->digits('bin');
  $calc->digits([0..7]);
  $calc->digits([qw(w a l d o)]);

If any of your "digits" has more than one character, to_base conversions
will technically work, but from_base will not give you the same number.
This is not supported, but UTF8 is perfectly okay to use.

=back

=head1 AUTHOR

Ken Williams, ken@forum.swarthmore.edu
Version 1.2 refactored by Brendan Byrd, BBYRD@CPAN.org

=head1 COPYRIGHT

This is free software in the colloquial nice-guy sense of the word.
Copyright (c) 1999, Ken Williams.  You may redistribute and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut