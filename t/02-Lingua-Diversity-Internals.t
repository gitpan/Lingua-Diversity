#!/usr/bin/perl

# Create dummy MyMeasure package...
package Lingua::Diversity::MyMeasure;
use Moose;
extends 'Lingua::Diversity';
use Lingua::Diversity::Internals qw( _validate_size );
sub measure {
    my ( $self, $unit_array_ref ) = @_;
    _validate_size(
        'unit_array_ref'    => $unit_array_ref,
        'max_num_items'     => 10,
    );
}
sub measure_per_category {
    my ( $self, $unit_array_ref, $category_array_ref ) = @_;
    _validate_size(
        'unit_array_ref'        => $unit_array_ref,
        'category_array_ref'    => $category_array_ref,
    );
}

package main;

use strict;
use warnings;

use Test::More tests => 15;

# Module is usable...
BEGIN {
    use_ok( 'Lingua::Diversity::Internals', qw(
        _validate_size
        _get_average
        _prepend_unit_with_category
    ) )
      || print "Bail out!\n";
}

# Subroutine _validate_size() requires parameter 'unit_array_ref'...
eval { _validate_size() };
is(
    ref $@,
    'Lingua::Diversity::X::Internals::ValidateSizeMissingParam',
    'Subroutine _validate_size() correctly croaks when called without '
 . q{parameter 'unit_array_ref'}
);

my $diversity = Lingua::Diversity::MyMeasure->new();

# Subroutine _validate_size() requires 1 array ref...
eval {
    $diversity->measure();
};
is(
    ref $@,
    'Lingua::Diversity::X::Internals::ValidateSizeMissing1stArrayRef',
    'Subroutine _validate_size() requires a first array ref'
);

# Subroutine _validate_size() correctly spots too small array...
eval {
    $diversity->measure( [] );
};
is(
    ref $@,
    'Lingua::Diversity::X::Internals::ValidateSizeArrayTooSmall',
    'Subroutine _validate_size() correctly spots too small array'
);

# Subroutine _validate_size() correctly spots too large array...
eval {
    $diversity->measure( [ 1..11 ] );
};
is(
    ref $@,
    'Lingua::Diversity::X::Internals::ValidateSizeArrayTooLarge',
    'Subroutine _validate_size() correctly spots too large array'
);

# Subroutine _validate_size() requires a 2nd array ref...
eval {
    $diversity->measure_per_category( [1], );
};
is(
    ref $@,
    'Lingua::Diversity::X::Internals::ValidateSizeMissing2ndArrayRef',
    'Subroutine _validate_size() may require a second array ref'
);

# Subroutine _validate_size() correctly spots arrays of unequal size...
eval {
    $diversity->measure_per_category( [ 1..11 ], [ 1..10 ] );
};
is(
    ref $@,
    'Lingua::Diversity::X::Internals::ValidateSizeArraysOfDifferentSize',
    'Subroutine _validate_size() correctly spots arrays of unequal size'
);

# Subroutine _get_average() correctly croaks at empty array ref...
eval {
    _get_average( [] );
};
is(
    ref $@,
    'Lingua::Diversity::X::Internals::GetAverageEmptyArray',
    'Subroutine _get_average() correctly croaks at empty array ref'
);

# Subroutine _get_average() correctly croaks at arrays of different size...
eval {
    _get_average( [ 1..10 ], [] );
};
is(
    ref $@,
    'Lingua::Diversity::X::Internals::GetAverageArraysOfDifferentSize',
    'Subroutine _get_average() correctly croaks at arrays of different size'
);

my @numbers = ( 2..4 );
my ( $average, $variance, $num_observations ) = _get_average(
    \@numbers,
);

# Subroutine _get_average() correctly computes unweighted average.
is(
    $average,
    3,
    'Subroutine _get_average() correctly computes unweighted average'
);

# Subroutine _get_average() correctly computes unweighted variance.
is(
    sprintf( "%.2f", $variance ),
    0.67,
    'Subroutine _get_average() correctly computes unweighted variance'
);

my @weights = ( 2, 1, 1 );
( $average, $variance, $num_observations ) = _get_average(
    \@numbers,
    \@weights,
);
# Subroutine _get_average() correctly computes weighted average.
is(
    $average,
    2.75,
    'Subroutine _get_average() correctly computes weighted average'
);

# Subroutine _get_average() correctly computes weighted variance.
is(
    sprintf( "%.2f", $variance ),
    0.69,
    'Subroutine _get_average() correctly computes weighted variance'
);

# Subroutine _get_average() correctly returns number of observations.
is(
    $num_observations,
    4,
    'Subroutine _get_average() correctly returns number of observations'
);

my $recoded_array_ref   = _prepend_unit_with_category(
    [ qw( can be can ) ],
    [ qw( VERB VERB NOUN ) ],
);

# Subroutine _prepend_unit_with_category() works correctly.
ok(
       $recoded_array_ref->[0] eq 'VERBcan'
    && $recoded_array_ref->[1] eq 'VERBbe'
    && $recoded_array_ref->[2] eq 'NOUNcan',
    'Subroutine _prepend_unit_with_category() works correctly'
);



