package Lingua::Diversity::Result;

use Moose;
use Moose::Util::TypeConstraints;

our $VERSION = '0.03';



#=============================================================================
# Attributes.
#=============================================================================

has 'diversity' => (
    is          => 'ro',
    isa         => 'Num',
    reader      => 'get_diversity',
    required    => 1,
);

has 'variance' => (
    is          => 'ro',
    isa         => 'Num',
    reader      => 'get_variance',
    predicate   => 'has_variance',
);

has 'count' => (
    is          => 'ro',
    isa         => 'Num',
    reader      => 'get_count',
    predicate   => 'has_count',
);




#=============================================================================
# Standard Moose cleanup.
#=============================================================================

no Moose;
__PACKAGE__->meta->make_immutable;


__END__


=head1 NAME

Lingua::Diversity::Result - storing the result of a diversity measurement

=head1 VERSION

This documentation refers to Lingua::Diversity::Result version 0.02.

=head1 SYNOPSIS

    use Lingua::Diversity::Result;

    # Given a Lingua::Diversity derived object and an array of data...
    
    # Measure diversity in the data and store the result in a Result object.
    my $result = $diversity->measure( \@data );
    
    # A Result object always has a main 'diversity' field...
    print "Diversity\t",    $result->get_diversity(),   "\n";

    # ... and may have a 'variance' and 'count' field...
    if ( $result->has_variance() ) {
        print "Variance\t", $result->get_variance(),    "\n";
    }
    if ( $result->has_count() ) {
        print "Count\t",    $result->get_count(),       "\n";
    }


=head1 DESCRIPTION

This class implements the result of a Lingua::Diversity derived object's
diversity measurement. All diversity measures return a main value stored in
the Result's 'diversity' attribute. Those measures for which the main value
is an average may also return the corresponding variance and count (i.e.
number of observations), which are then stored in the Result's 'variance'
and 'count' attributes (this should be documented in the Lingua::Diversity
derived class).

=head1 CREATOR

The creator (C<new()>) returns a new Lingua::Diversity::Result object.
In principle, the end user should never use it directly since it is invoked
directly by the C<measure()> and C<measure_per_category()> methods of a given
Lingua::Diversity derived class.

The constructor takes one required and two optional named parameters:

=over 4

=item diversity (required)

A number characterizing the diversity measured in the data.

=item variance

If the value of the 'diversity' attribute is an average, this attribute
may contain the corresponding variance.

=item count

If the value of the 'diversity' attribute is an average, this attribute
may contain the corresponding number of observations. In the case of a
weighted average, the value of this attribute is the sum of weights, which
needs not be an integer.

=back

=head1 ACCESSORS AND PREDICATES

=over 4

=item get_diversity()

Getter for the 'diversity' attribute.

=item get_variance() and has_variance()

Getter and predicate for the 'variance' attribute.

=item get_count() and has_count()

Getter and predicate for the 'count' attribute.

=back

=head1 DEPENDENCIES

This module is part of the L<Lingua::Diversity> distribution, and extends
L<Lingua::Diversity>.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Aris Xanthos (aris.xanthos@unil.ch)

Patches are welcome.

=head1 AUTHOR

Aris Xanthos  (aris.xanthos@unil.ch)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Aris Xanthos (aris.xanthos@unil.ch).

This program is released under the GPL license (see
L<http://www.gnu.org/licenses/gpl.html>).

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

L<Lingua::Diversity>

