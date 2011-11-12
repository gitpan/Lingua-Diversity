#!/usr/bin/perl

# Dummy package for testing abstract method exception...
package Dummy;
use Moose;
extends 'Lingua::Diversity';
no Moose;
__PACKAGE__->meta->make_immutable;


# Main package...

package main;

use strict;
use warnings;

use Test::More tests => 7;

# Module is usable...
BEGIN {
    use_ok( 'Lingua::Diversity' ) || print "Bail out!\n";
}

my $diversity;

$diversity = Lingua::Diversity->new();

# Created objects are of the right class...
cmp_ok(
    ref( $diversity ), 'eq', 'Lingua::Diversity',
    'is a Lingua::Diversity'
);

# Created object have all necessary methods defined...
can_ok( $diversity, qw(
    measure
    measure_per_category
) );

# Method measure() can't be called on abstract object...
eval { $diversity->measure() };
is(
    ref $@,
    'Lingua::Diversity::X::AbstractObject',
    'Method measure() correctly croaks when called on abstract object'
);

# Method measure() must be implemented in derived classes...
my $other_diversity = Dummy->new();
eval { $other_diversity->measure(); };
is(
    ref $@,
    'Lingua::Diversity::X::AbstractMethod',
    'Method measure() correctly croaks when not implemented in '
  . 'derived classes'
);

# Method measure_per_category() can't be called on abstract object...
eval { $diversity->measure_per_category() };
is(
    ref $@,
    'Lingua::Diversity::X::AbstractObject',
    'Method measure_per_category() correctly croaks when called on '
  . 'abstract object'
);

# Method measure_per_category() must be implemented in derived classes...
$other_diversity = Dummy->new();
eval { $other_diversity->measure_per_category(); };
is(
    ref $@,
    'Lingua::Diversity::X::AbstractMethod',
    'Method measure_per_category() correctly croaks when not implemented in '
  . 'derived classes'
);




