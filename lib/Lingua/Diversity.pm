package Lingua::Diversity;

use Moose;
use Moose::Util::TypeConstraints;

our $VERSION = '0.02';

use Lingua::Diversity::Result;
use Lingua::Diversity::X;


#=============================================================================
# Subtypes definitions.
#=============================================================================

subtype 'Natural',
    as 'Int',
    where { $_ > 0 };


#=============================================================================
# Public abstract instance methods.
#=============================================================================

#-----------------------------------------------------------------------------
# ABSTRACT Method measure
#-----------------------------------------------------------------------------
# Synopsis:      Apply the selected measure.
# Arguments:     - A reference to an array of units (in the text's order).
# Return values: - A Lingua::Diversity::Result object.
#-----------------------------------------------------------------------------

sub measure {
    my ( $self ) = @_;
    
    # Get object's class.
    my $class = ref( $self );

    # Abstract object exception...
    Lingua::Diversity::X::AbstractObject->throw()
        if $class eq 'Lingua::Diversity';

    # Abstract method exception...
    Lingua::Diversity::X::AbstractMethod->throw(
        'class'     => $class,
        'method'    => 'measure',
    );
}


#-----------------------------------------------------------------------------
# ABSTRACT Method measure_per_category
#-----------------------------------------------------------------------------
# Synopsis:      Apply the selected measure per category.
# Arguments:     - A reference to an array of units (in the text's order).
#                - A reference to an array of categories (in the same order).
# Return values: - A Lingua::Diversity::Result object.
#-----------------------------------------------------------------------------

sub measure_per_category {
    my ( $self ) = @_;

    # Get object's class.
    my $class = ref( $self );

    # Abstract object exception...
    Lingua::Diversity::X::AbstractObject->throw()
        if $class eq 'Lingua::Diversity';

    # Abstract method exception...
    Lingua::Diversity::X::AbstractMethod->throw(
        'class'     => $class,
        'method'    => 'measure_per_category',
    );
}


#=============================================================================
# Standard Moose cleanup.
#=============================================================================

no Moose;
__PACKAGE__->meta->make_immutable;


__END__


=head1 NAME

Lingua::Diversity - Measuring diversity of text units

=head1 VERSION

This documentation refers to Lingua::Diversity version 0.02.

=head1 SYNOPSIS

    use Lingua::Diversity::MTLD;
    use Lingua::Diversity::Utils qw( split_text split_tagged_text );

    my $text = 'of the people, by the people, for the people';

    # Create a Diversity object (here using method 'MTLD')...
    my $diversity = Lingua::Diversity::MTLD->new();

    # Given some text, get a reference to an array of words...
    my $word_array_ref = split_text(
        'text'      => \$text,
        'regexp'    => qr{[^a-zA-Z]+},
    );

    # Measure lexical diversity...
    my $result = $diversity->measure( $word_array_ref );
    
    # Display results...
    print "Lexical diversity:       ", $result->get_diversity(), "\n";
    print "Variance:                ", $result->get_variance(),  "\n";

    # Tag text using Lingua::TreeTagger...
    use Lingua::TreeTagger;
    my $tagger = Lingua::TreeTagger->new(
        'language' => 'english',
        'options'  => [ qw( -token -lemma -no-unknown ) ],
    );
    my $tagged_text = $tagger->tag_text( \$text );

    # Get references to an array of wordforms and an array of lemmas...
    my ( $wordform_array_ref, $lemma_array_ref ) = split_tagged_text(
        'tagged_text'   => $tagged_text,
        'unit'          => 'original',
        'category'      => 'lemma',
    );

    # Measure morphological diversity...
    $result = $diversity->measure_per_category(
        $wordform_array_ref,
        $lemma_array_ref,
    );

    # Display results...
    print "Morphological diversity: ", $result->get_diversity(), "\n";
    print "Variance:                ", $result->get_variance(),  "\n";


=head1 DESCRIPTION

This distribution provides a simple object-oriented interface for applying
various measures of diversity to text units. At present, the only implemented
measure is MTLD (see L<Lingua::Diversity::MTLD>), but there's more to come.

Note that the Lingua::Diversity class is meant to serve as a base class for
classes such as L<Lingua::Diversity::MTLD>, which implement specific diversity
measures. Clients should always instantiate the specific classes instead of
this one (see L</SYNOPSIS>).

=head1 METHODS

=over 4

=item measure()

Apply the selected diversity measure and return the result in a new
L<Lingua::Diversity::Result> object.

The method requires a reference to a non-empty array of text units (typically
words) as argument.

Units should be in the text's order, since some measures (e.g. MTLD) take it
into account. Specific measures may set conditions on the minimal or maximal
number of units and raise exceptions when these conditions are not met (see
subroutine C<_validate_size()> in
L<Lingua::Diversity::Internals|Lingua::Diversity::Internals/SUBROUTINES>).

The L<Lingua::Diversity::Utils> module contained within this distribution
provides tools for helping with the creation of the array of units.

=item measure_per_category()

Apply the selected diversity measure per category and return the result in a
new Lingua::Diversity::Result object. For instance, units might be wordforms
and categories might be lemmas, so that the result would correspond to the
diversity of wordforms per lemma (i.e. an estimate of the text's morphological
diversity).

Units should be in the text's order, since some measures (e.g. MTLD) take it
into account. Specific measures may set conditions on the minimal or maximal
number of units and raise exceptions when these conditions are not met (see
subroutine C<_validate_size()> in
L<Lingua::Diversity::Internals|Lingua::Diversity::Internals/SUBROUTINES>).
There should be the same number of items in the unit and category array.

The L<Lingua::Diversity::Utils> module contained within this distribution
provides tools for helping with the creation of the array of units and lemmas.

=back

=head1 DIAGNOSTICS

=over 4

=item Call to abstract method CLASS::METHOD

This exception is raised when either method C<measure()> or method
C<measure_per_category()> is called while it is not supported by the selected
measure.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Some subroutines in module Lingua::Diversity::Utils require a working
version of TreeTagger (available at
L<http://www.ims.uni-stuttgart.de/projekte/corplex/TreeTagger>).

=head1 DEPENDENCIES

This is the base module of the Lingua::Diversity distribution, which comprises
modules L<Lingua::Diversity::Result>, L<Lingua::Diversity::Utils>,
L<Lingua::Diversity::Internals>, L<Lingua::Diversity::X>,
and L<Lingua::Diversity::MTLD>.

The Lingua::Diversity distribution uses CPAN modules
L<Moose>, L<Exception::Class>, and optionally L<Lingua::TreeTagger>.

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

L<Lingua::Diversity::MTLD>, L<Lingua::Diversity::Result>,
L<Lingua::Diversity::Utils>, L<Lingua::Diversity::Internals>,
L<Lingua::Diversity::X>, and L<Lingua::TreeTagger>.


