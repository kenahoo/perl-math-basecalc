package Math::BaseCalc;

use strict;
use vars qw($VERSION);

$VERSION = '$Revision: 1.4 $';

sub new {
    my ($pack, %opts) = @_;
    $opts{digits} = [0,1] if $opts{digits} eq 'binary'; # ...etc
    return bless \%opts, $pack;
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
    return $result;
}


1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Math::BaseCalc - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Math::BaseCalc;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Math::BaseCalc was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut
