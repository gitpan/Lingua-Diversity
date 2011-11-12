#!/usr/bin/perl

package Lingua::Diversity::Internals;

use strict;
use warnings;
use Carp;

use Exporter   ();

our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(
    _validate_size
    _get_average
    _prepend_unit_with_category
);

our $VERSION     = 0.01;

use Lingua::Diversity::X;


#=============================================================================
# Subroutines
#=============================================================================

#-----------------------------------------------------------------------------
# Subroutine _validate_size
#-----------------------------------------------------------------------------
# Synopsis:      Validate the array arguments of methods measure() and
#                measure_per_category().
# Parameters:    - unit_array_ref:     a non-empty array of text units.
#                - category_array_ref: a non-empty array of categories.
# Return values: None.
#-----------------------------------------------------------------------------

sub _validate_size {
    my ( %parameter ) = @_;
    
    # Parameter 'unit_array_ref' is required...
    Lingua::Diversity::X::Internals::ValidateSizeMissingParam->throw()
        if ! exists $parameter{'unit_array_ref'};

    # Get caller method...
    my $method = ( caller(1) )[3];

    # Parameter 'unit_array_ref' must be a ref to an array...
    if ( ref $parameter{'unit_array_ref'} ne 'ARRAY' ) {
        Lingua::Diversity::X::Internals::ValidateSizeMissing1stArrayRef->throw(
            'method' => $method,
        )
    }

    # Default min number of items is 1...
    $parameter{'min_num_items'} ||= 1;
    
    # Get number of items in unit array.
    my $num_items = @{ $parameter{'unit_array_ref'} };

    # Validate min number of items...
    if ( $num_items < $parameter{'min_num_items'} ) {
        Lingua::Diversity::X::Internals::ValidateSizeArrayTooSmall->throw(
            'method'        => $method,
            'num_items'     => $num_items,
            'min_num_items' => $parameter{'min_num_items'},
        );
    }

    # Validate max number of items...
    if (
           defined $parameter{'max_num_items'}
        && $num_items > $parameter{'max_num_items'}
    ) {
        Lingua::Diversity::X::Internals::ValidateSizeArrayTooLarge->throw(
            'method'        => $method,
            'num_items'     => $num_items,
            'max_num_items' => $parameter{'max_num_items'},
        );
    }

    # If caller is measure_per_category...
    if ( $method =~ qr{measure_per_category$} ) {

        # Parameter 'unit_array_ref' must be a ref to an array...
        if ( ref $parameter{'category_array_ref'} ne 'ARRAY' ) {
            Lingua::Diversity::X::Internals::ValidateSizeMissing2ndArrayRef->throw(
                'method' => $method,
            )
        }

        # Get number of items in category array.
        my $num_categories = scalar @{ $parameter{'category_array_ref'} };

        # Check that arrays have the same size...
        if ( $num_items != $num_categories ) {
            Lingua::Diversity::X::Internals::ValidateSizeArraysOfDifferentSize->throw(
                'method'            => $method,
                'num_units'         => $num_items,
                'num_categories'    => $num_categories,
            );
        }
    }

    return;
}


#-----------------------------------------------------------------------------
# Subroutine _get_average
#-----------------------------------------------------------------------------
# Synopsis:      Computes the (possible weighted) average and variance of
#                an array of numbers.
# Arguments:     - A reference to a non-empty array.
#                - An optional reference to an array of weights of same size.
# Return values: - The (possibly weighted) average.
#                - The (possibly weighted) variance.
#                - The number of observations.
#-----------------------------------------------------------------------------

sub _get_average {
    my ( $number_array_ref, $weight_array_ref ) = @_;

    # Get number of items in array.
    my $number_of_items = @$number_array_ref;

    # Number array must not be empty...
    Lingua::Diversity::X::Internals::GetAverageEmptyArray->throw()
        if $number_of_items == 0;

    # Weight array must have the same size as number array (if provided)...
    if (
           defined $weight_array_ref
        && @$weight_array_ref != $number_of_items
    ) {
        Lingua::Diversity::X::Internals::GetAverageArraysOfDifferentSize->throw()
    }

    # Set the default, uniform weight if no weights were provided.
    my $uniform_weight = ( defined $weight_array_ref ? undef : 1 );

    my $sum_of_weights          = 0;
    my $weighted_sum            = 0;
    my $weighted_sum_squares    = 0;

    NUMBER_INDEX:
    foreach my $index ( 0..@$number_array_ref-1 ) {
        my $number = $number_array_ref->[$index];
        my $weight = ( $uniform_weight ? 1 : $weight_array_ref->[$index] );
        $sum_of_weights         += $weight;
        $weighted_sum           += $weight * $number;
        $weighted_sum_squares   += $weight * $number * $number;
    }

    # Compute average and variance...
    my $average  = $weighted_sum / $sum_of_weights;
    my $variance = $weighted_sum_squares / $sum_of_weights
                 - $average * $average
                 ;

    return $average, $variance, $sum_of_weights;
}


#-----------------------------------------------------------------------------
# Subroutine _prepend_unit_with_category
#-----------------------------------------------------------------------------
# Synopsis:      Prepend every unit in an array with its category.
# Arguments:     - A reference to an array of units.
#                - A reference to an array of categories of same size.
# Return values: - A reference to an array of recoded units.
#-----------------------------------------------------------------------------

sub _prepend_unit_with_category {
    my ( $unit_array_ref, $category_array_ref ) = @_;

    my @recoded_array;
    
    ITEM_INDEX:
    foreach my $item_index ( 0..@$unit_array_ref-1 ) {

        # Prepend unit with category and add to recoded array.
        push @recoded_array,
                $category_array_ref->[$item_index]
              . $unit_array_ref->[$item_index]
              ;
    }
    
    return \@recoded_array;
}



__END__


=head1 NAME

Lingua::Diversity::Internals - utility subroutines for developers of classes
derived from Lingua::Diversity

=head1 VERSION

This documentation refers to Lingua::Diversity::Internals version 0.01.

=head1 SYNOPSIS

    package Lingua::Diversity::MyMeasure;

    use Moose;

    extends 'Lingua::Diversity';

    use Lingua::Diversity::Internals qw(
        _validate_size
        _get_average
        _prepend_unit_with_category
    );
    
    sub measure {
        my ( $self, $array_ref ) = @_;

        _validate_size(
            'unit_array_ref'    => $array_ref,
            'min_num_items'     => 50,
            'max_num_items'     => 1000000,
        );

        # Further instructions, until at some point...
        my @numbers = 1..100;
        my (
            $average,
            $variance,
            $num_observations,
        ) = _get_average( \@numbers );
        
        # More instructions...
    }

    sub measure_per_category {
        my ( $self, $unit_array_ref, $category_array_ref ) = @_;

        _validate_size(
            'unit_array_ref'        => $unit_array_ref,
            'category_array_ref'    => $category_array_ref,
            'min_num_items'         => 50,
            'max_num_items'         => 1000000,
        );

        # Recode units to avoid homophony...
        my $recoded_unit_array_ref = _prepend_unit_with_category(
            $unit_array_ref,
            $category_array_ref,
        );

        # Further instructions, until at some point...
        my @numbers = 1..100;
        my @weights = 1..100;
        my (
            $weighted_average,
            $weighted_variance,
            $num_observations,
        ) = _get_average( \@numbers, \@weights );

        # Yet more instructions...
    }


=head1 DESCRIPTION

This module provides utility subroutines intended to facilitate the
development of of classes derived from L<Lingua::Diversity>. These subroutines
are marked as internal because they are meant to be used by developers
creating classes derived from L<Lingua::Diversity> (as opposed to being used
by clients of such classes).

=head1 SUBROUTINES

=over 4

=item C<_validate_size()>

Check that the subroutine is called with at least a parameter 'unit_array_ref'
containing an array ref. Check that the size of the array is within specified
bounds. If called from within method C<measure_per_category()>, further check
that a second array ref is provided, and that it has the same size as the
first.

NB: This subroutine is meant to be used within implementations of methods
C<measure()> and C<measure_per_category()>. Use of this subroutine in other
contexts has not been tested and probably doesn't make any sense.

The subroutine requires one named parameter and may take up to four of them.

=over 4

=item unit_array_ref (required)

A reference to an array of text units (e.g. words).

=item category_array_ref

A reference to an array of categories (e.g. lemmas).

=item min_num_items

The minimum number of items that should be in the array(s).

=item max_num_items

The maximum number of items that should be in the array(s).

=back

=item C<_get_average()>

Compute the (possibly weighted) average and variance of a list of numbers.
Return the average, variance, and number of observations.

The subroutine requires a reference to an array of numbers as argument.
Passing an empty array throws an exception.

Optionally, a reference to an array of counts may be passed as a second
argument. An exception is thrown if this array's size does not match the first
one. Counts may be real instead of integers, in which case the number of
observations returned may not be an integer.

=item C<_prepend_unit_with_category()>

Take a reference to an array of units and an array of categories, and return
a reference to an array where each element is a unit prepended with its
category. E.g. from units C<[ qw( can be can ) ]> and categories
C<[ qw( VERB VERB NOUN ) ]> return C<[ qw( VERBcan VERBbe NOUNcan ) ]>.

It is recommended to use such a recoded array of units instead of the original
one when writing the C<measure_per_category()> method. This makes it possible
to process separately homophonous units that correspond to distinct
categories, such as 'can' as a verb or noun form in the above example.

NB: It is assumed that two non-empty arrays of identical size are passed in
argument, which can and should be checked previously with subroutine
C<_validate_size()>.

=back

=head1 DIAGNOSTICS

The following error message targets developers of classes derived from
L<Lingua::Diversity>:

=over 4

=item Missing parameter 'unit_array_ref' in call to subroutine
_validate_size()

This exception is raised when subroutine C<_validate_size()> is called without
its only required argument, 'unit_array_ref' (a reference to an array).

=back

The following error messages target clients of classes derived from
L<Lingua::Diversity>. They should be copied verbatim in the documentation of
these classes when the corresponding subroutines are used.

=over 4

=item Method [measure()/measure_per_category()] must be called with a
reference to an array as 1st argument

This exception is raised when either method L<measure()> or method
L<measure_per_category()> is called without a reference to an array as a
first argument.

=item Method measure_per_category() must be called with a reference to an
array as 2nd argument

This exception is raised when method L<measure_per_category()> is called
without a reference to an array as a second argument.

=item Method [measure()/measure_per_category()] was called with an array
containing N item(s) while this measure requires [at least/at most] M item(s)

This exception is raised when either method L<measure()> or method
L<measure_per_category()> is called with an argument array that is either too
small or too large relative to conditions set by the selected measure.

=back

=head1 DEPENDENCIES

This module is part of the L<Lingua::Diversity> distribution.

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

