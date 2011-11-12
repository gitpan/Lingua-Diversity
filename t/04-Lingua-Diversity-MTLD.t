#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 21;

# Module is usable...
BEGIN {
    use_ok( 'Lingua::Diversity::MTLD' ) || print "Bail out!\n";
}

my $diversity;

$diversity = Lingua::Diversity::MTLD->new();

# Created objects are of the right class...
cmp_ok(
    ref( $diversity ), 'eq', 'Lingua::Diversity::MTLD',
    'is a Lingua::Diversity::MTLD'
);

# Created object have all necessary methods defined...
can_ok( $diversity, qw(
    measure
    measure_per_category
    _get_factor_length_average
) );

my $unit_array_ref = [ qw( a b a b a b a b c b ) ];

my ( $average, $variance, $count ) = $diversity->_get_factor_length_average(
    $unit_array_ref,
);

# Method _get_factor_length_average() correctly computes average (1 array)...
is(
    sprintf( "%.3f", $average ),
    3.457,
    'Method _get_factor_length_average() correctly computes average (1 array)'
);

# Method _get_factor_length_average() correctly computes variance (1 array)...
is(
    sprintf( "%.3f", $variance ),
    0.467,
    'Method _get_factor_length_average() correctly computes variance '
  . '(1 array)'
);

# Method _get_factor_length_average() correctly computes count (1 array)...
is(
    sprintf( "%.3f", $count ),
    2.893,
    'Method _get_factor_length_average() correctly computes count (1 array)'
);

my $category_array_ref     = [ qw( A A B B B A A A A B ) ];

use Lingua::Diversity::Internals qw( _prepend_unit_with_category );

my $recoded_unit_array_ref = _prepend_unit_with_category(
    $unit_array_ref,
    $category_array_ref,
);

( $average, $variance, $count ) = $diversity->_get_factor_length_average(
    $recoded_unit_array_ref,
    $category_array_ref,
);

# Method _get_factor_length_average() correctly computes average (2 arrays)...
is(
    sprintf( "%.3f", $average ),
    3.333,
    'Method _get_factor_length_average() correctly computes average '
  . '(2 arrays)'
);

# Method _get_factor_length_average() correctly computes variance (2 arrays)..
is(
    sprintf( "%.3f", $variance ),
    0.222,
    'Method _get_factor_length_average() correctly computes variance '
  . '(2 arrays)'
);

# Method _get_factor_length_average() correctly computes count (2 arrays)...
is(
    $count,
    3,
    'Method _get_factor_length_average() correctly computes count (2 arrays)'
);

my $result = $diversity->measure( $unit_array_ref );

# Method _measure() correctly computes average...
is(
    sprintf( "%.3f", $result->get_diversity() ),
    3.228,
    'Method _measure() correctly computes average'
);

# Method _measure() correctly computes variance...
is(
    sprintf( "%.3f", $result->get_variance() ),
    0.234,
    'Method _measure() correctly computes variance'
);

# Method _measure() correctly computes count...
is(
    sprintf( "%.3f", $result->get_count() ),
    2.946,
    'Method _measure() correctly computes count'
);

$result
   = $diversity->measure_per_category( $unit_array_ref, $category_array_ref );

# Method _measure_per_category() correctly computes average...
is(
    $result->get_diversity(),
    3,
    'Method _measure_per_category() correctly computes average'
);

# Method _measure_per_category() correctly computes variance...
is(
    sprintf( "%.3f", $result->get_variance() ),
    0.222,
    'Method _measure_per_category() correctly computes variance'
);

# Method _measure_per_category() correctly computes count...
is(
    $result->get_count(),
    3,
    'Method _measure_per_category() correctly computes count'
);

$diversity->set_weighting_mode( 'within_and_between' );
$result = $diversity->measure( $unit_array_ref );

# Method _measure() correctly computes weighted average...
is(
    sprintf( "%.3f", $result->get_diversity() ),
    3.224,
    'Method _measure() correctly computes weighted average'
);

# Method _measure() correctly computes weighted variance...
is(
    sprintf( "%.3f", $result->get_variance() ),
    0.229,
    'Method _measure() correctly computes weighted variance'
);

# Method _measure() correctly computes weighted count...
is(
    sprintf( "%.3f", $result->get_count() ),
    2.947,
    'Method _measure() correctly computes weighted count'
);

$result
  = $diversity->measure_per_category( $unit_array_ref, $category_array_ref );

# Method _measure_per_category() correctly computes weighted average...
is(
    $result->get_diversity(),
    3,
    'Method _measure_per_category() correctly computes weighted average'
);

# Method _measure_per_category() correctly computes weighted variance...
is(
    sprintf( "%.3f", $result->get_variance() ),
    0.222,
    'Method _measure_per_category() correctly computes weighted variance'
);

# Method _measure_per_category() correctly computes weighted count...
is(
    $result->get_count(),
    3,
    'Method _measure_per_category() correctly computes weighted count'
);




