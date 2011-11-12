use strict;
use warnings;

use Test::Pod::Coverage tests => 5;

my @modules_to_be_tested = qw(
    Lingua::Diversity
    Lingua::Diversity::Result
    Lingua::Diversity::Internals
    Lingua::Diversity::Utils
    Lingua::Diversity::MTLD
);

foreach my $module ( @modules_to_be_tested ) {
    pod_coverage_ok( $module, "$module is covered" );
}
