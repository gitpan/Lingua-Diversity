package Lingua::Diversity::MTLD;

use Moose;
use Moose::Util::TypeConstraints;

our $VERSION = '0.01';

extends 'Lingua::Diversity';

use Lingua::Diversity::Internals qw(
    _get_average
    _validate_size
    _prepend_unit_with_category
);


#=============================================================================
# Subtypes definitions.
#=============================================================================

enum 'WeightingMode', [ qw( within_only within_and_between ) ];

subtype 'BetweenZeroAndOneExcl',
    as 'Num',
    where { $_ > 0 && $_ < 1 };


#=============================================================================
# Attributes.
#=============================================================================

has 'threshold' => (
    is          => 'rw',
    isa         => 'BetweenZeroAndOneExcl',
    reader      => 'get_threshold',
    writer      => 'set_threshold',
    default     => 0.72,
);

has 'weighting_mode' => (
    is          => 'rw',
    isa         => 'WeightingMode',
    reader      => 'get_weighting_mode',
    writer      => 'set_weighting_mode',
    default     => 'within_only',
);


#=============================================================================
# Public instance methods.
#=============================================================================

#-----------------------------------------------------------------------------
# Method measure
#-----------------------------------------------------------------------------
# Synopsis:      Apply the Resampling diversity measure.
# Arguments:     - A reference to an array of units.
# Return values: - A Lingua::Diversity::Result object.
#-----------------------------------------------------------------------------

sub measure {
    my ( $self, $array_ref ) = @_;

    # Validate argument array...
    _validate_size(
        'unit_array_ref'    => $array_ref,
    );
    
    # Get factor length Average, Variance, and Count (left-to-right pass)...
    my @left_to_right_AVC = $self->_get_factor_length_average(
        $array_ref
    );

    # Right-to-left pass...
    my @right_to_left_AVC = $self->_get_factor_length_average(
        [ reverse @$array_ref ]
    );

    # Assign weights if requested.
    my $weights_ref = (
        $self->get_weighting_mode() eq 'within_only'     ?
        [ 1, 1 ]                                         :
        [ $left_to_right_AVC[2], $right_to_left_AVC[2] ]
    );
    
    # Get average results (between the two passes)...
    my %result;
    my @fields = qw( average variance count );
    foreach my $field ( @fields ) {
        ( $result{$field} ) = _get_average(
            [ shift( @left_to_right_AVC ), shift( @right_to_left_AVC ) ],
            $weights_ref,
        );
    }
    
    # Create, fill, and return a new Result object...
    return Lingua::Diversity::Result->new(
        'diversity' => $result{'average'},
        'variance'  => $result{'variance'},
        'count'     => $result{'count'},
    );
}


#-----------------------------------------------------------------------------
# Method measure_per_category
#-----------------------------------------------------------------------------
# Synopsis:      Apply the selected measure per category.
# Arguments:     - A reference to an array of units (in the text's order).
#                - A reference to an array of categories (in the same order).
# Return values: - A Lingua::Diversity::Result object.
#-----------------------------------------------------------------------------

sub measure_per_category {
    my ( $self, $unit_array_ref, $category_array_ref ) = @_;

    # Validate argument arrays...
    _validate_size(
        'unit_array_ref'        => $unit_array_ref,
        'category_array_ref'    => $category_array_ref,
    );

    # Prepend each unit with its category...
    my $recoded_unit_array_ref = _prepend_unit_with_category(
        $unit_array_ref,
        $category_array_ref,
    );

    # Get factor length Average, Variance, and Count (left-to-right pass)...
    my @left_to_right_AVC = $self->_get_factor_length_average(
        $recoded_unit_array_ref,
        $category_array_ref,
    );

    # Right-to-left pass...
    my @right_to_left_AVC = $self->_get_factor_length_average(
        [ reverse @$recoded_unit_array_ref ],
        [ reverse @$category_array_ref ]
    );

    # Assign weights if requested.
    my $weights_ref = (
        $self->get_weighting_mode() eq 'within_only'     ?
        [ 1, 1 ]                                         :
        [ $left_to_right_AVC[2], $right_to_left_AVC[2] ]
    );

    # Get average results (between the two passes)...
    my %result;
    my @fields = qw( average variance count );
    foreach my $field ( @fields ) {
        ( $result{$field} ) = _get_average(
            [ shift( @left_to_right_AVC ), shift( @right_to_left_AVC ) ],
            $weights_ref,
        );
    }

    # Create, fill, and return a new Result object...
    return Lingua::Diversity::Result->new(
        'diversity' => $result{'average'},
        'variance'  => $result{'variance'},
        'count'     => $result{'count'},
    );
}



#=============================================================================
# Private instance methods.
#=============================================================================

#-----------------------------------------------------------------------------
# Method _get_factor_length_average
#-----------------------------------------------------------------------------
# Synopsis:      Computes factor length average, variance, and count.
# Arguments:     - A reference to an array of units (required).
#                - A reference to an array of categories (optional).
# Return values: - A Lingua::Diversity::Result object.
#-----------------------------------------------------------------------------

sub _get_factor_length_average {
    my ( $self, $unit_array_ref, $category_array_ref ) = @_;

    my ( @factor_lengths, @factor_weights );
    my ( %unit_type_list, %category_type_list );

    # Get type-token ratio threshold.
    my $threshold = $self->get_threshold();

    # Initialize token count and type-token ratio.
    my ( $token_count, $type_token_ratio ) = ( 0, 1 );

    TOKEN_INDEX:
    foreach my $token_index ( 0..@$unit_array_ref-1 ) {

        # Increase token count.
        $token_count++;
        
        # Get and store unit type for this token...
        my $unit = $unit_array_ref->[$token_index];
        $unit_type_list{$unit} = 1;

        # Get type-token ratio.
        $type_token_ratio = keys( %unit_type_list ) / $token_count;

        # If category array if available...
        if( defined $category_array_ref ) {

            # Get and store category type for this token...
            my $category = $category_array_ref->[$token_index];
            $category_type_list{$category} = 1;

            # Divide type-token ratio by category type count.
            $type_token_ratio /= keys( %category_type_list );
        }

        # If type-token ratio is less than or equal to threshold...
        if ( $type_token_ratio <= $threshold ) {

            # Store current factor length (i.e. token count) and weight (1)...
            push @factor_lengths, $token_count;
            push @factor_weights, 1;

            # Reset token count, type-token ratio, and type lists...
            $token_count      = 0;
            $type_token_ratio = 1;
            undef %unit_type_list;
            undef %category_type_list;
        }
    }

    # If there is a 'partial' factor (see McCarthy & Jarvis 2010)...
    if ( $type_token_ratio < 1 ) {

        # Get and store factor weight (i.e. proportion of threshold attained).
        my $proportion_threshold = ( 1-$type_token_ratio ) / ( 1-$threshold );
        push @factor_weights, $proportion_threshold;
        
        # Interpolate and store factor length.
        push @factor_lengths, $token_count / $proportion_threshold;
    }

    # Compute and return factor length average, variance, and count.
    return _get_average( \@factor_lengths, \@factor_weights );
}



#=============================================================================
# Standard Moose cleanup.
#=============================================================================

no Moose;
__PACKAGE__->meta->make_immutable;


__END__


=head1 NAME

Lingua::Diversity::MTLD - 'MTLD' method for measuring diversity

=head1 VERSION

This documentation refers to Lingua::Diversity::MTLD version 0.01.

=head1 SYNOPSIS

    use Lingua::Diversity::MTLD;
    use Lingua::Diversity::Utils qw( split_text split_tagged_text );

    my $text = 'of the people, by the people, for the people';

    # Create a Diversity object...
    my $diversity = Lingua::Diversity::MTLD->new(
        'threshold'         => 0.71,
        'weighting_mode'    => 'within_and_between',
    );

    # Given some text, get a reference to an array of words...
    my $word_array_ref = split_text(
        'text'          => \$text,
        'unit_regexp'   => qr{[^a-zA-Z]+},
    );

    # Measure lexical diversity...
    my $result = $diversity->measure( $word_array_ref );
    
    # Display results...
    print "Lexical diversity:       ", $result->get_diversity(), "\n";
    print "Variance:                ", $result->get_variance(),  "\n";

    # Tag a file using Lingua::TreeTagger...
    use Lingua::TreeTagger;
    my $tagger = Lingua::TreeTagger->new(
        'language' => 'english',
        'options'  => [ qw( -token -lemma -no-unknown ) ],
    );
    my $tagged_text = $tagger->tag_file( 'path/to/some/file.txt' );

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

This module implements the 'MTLD' method for measuring the diversity
of text units. MTLD stands for Measure of Textual Lexical Diversity, which is
also known as LDAT (Lexical Diversity Assessment Tool), cf. McCarthy, P.M., &
Jarvis, S. (2010) 'MTLD, vocd-D, and HD-D: A validation study of sophisticated
approaches to lexical diversity assessment', Behavior Research Methods, 42(2):
381-392.

The MTLD method is based on the type-token ratio of a text, i.e. the ratio of
the number of distinct words--or more generally text units--to the total
number of units. Leaving aside the nasty details, the idea is to compute the
average length of a sequence of contiguous text units maintaining a type-token
ratio above a specified threshold, which is set to 0.72 by McCarthy and Jarvis
(2010). They call such a sequence a 'factor' of the text.

The present implementation also returns the variance of factor length, as well
as the number of observations, which in most cases will not be an integer (see
the notion of 'partial factor' in McCarthy and Jarvis (2010) for a detailed
explanation of why it is so.

This implementation also attempts to generalize the authors' original idea to
the computation of morphological diversity (see method
C<measure_per_category()> below.

=head1 CREATOR

The creator (C<new()>) returns a new Lingua::Diversity::MTLD object. It
takes two optional named parameters:

=over 4

=item threshold

The TTR value which a sequence of contiguous text units must maintain to
constitute a 'factor'. It should be comprised between 0 and 1 exclusive.
Default value is 0.72, following McCarthy and Jarvis (2010).

=item weighting_mode

The computation of MTLD is performed two times, once in left-to-right text
order and once in right-to-left text order. Each pass yields a weighted
average (and variance), and the two averages are in turned averaged to get the
value that is finally reported. This attribute indicates whether the reported
average should itself be weighted according to the potentially different
number of observations in the two passes (value 'within_and_between'), or not
(value 'within_only'). The default value is 'within_only', as in the paper of
McCarthy and Jarvis, although the author of this implementation finds it more
consistent to select 'within_and_between'.

=back

=head1 ACCESSORS

=over 4

=item C<get_threshold()> and C<set_threshold()>

Getter and setter for the threshold attribute.

=item C<get_weighting_mode()> and C<set_weighting_mode()>

Getter and setter for the weighting_mode attribute.

=back

=head1 METHODS

=over 4

=item C<measure()>

Apply the diversity measure and return the result in a new
Lingua::Diversity::Result object. The result includes the average, variance,
and number of observations.

The method requires a reference to a non-empty array of text units (typically
words) as argument. Units should be in the text's order.

The L<Lingua::Diversity::Utils> module contained within the
L<Lingua::Diversity> distribution provides tools for helping with the creation
of the array of units.

=item C<measure_per_category()>

Apply the diversity measure per category and return the result in a
new Lingua::Diversity::Result object. For instance, units might be wordforms
and categories might be lemmas, so that the result would correspond to the
diversity of wordforms per lemma (i.e. an estimate of the text's morphological
diversity).  The result includes the average, variance, and number of
observations.

The original method described by McCarthy and Jarvis (2010) is modified by
replacing the type count in the type-token ratio with the number of unit types
(e.g. wordform types) divided by the number of category types (e.g. lemma
types).

The method requires a reference to a non-empty array of text units and a
reference to a non-empty array of categories as arguments. Units and
categories should be in the text's order and in one-to-one correspondence (so
that there should be the same number of items in the unit and category
arrays).

The L<Lingua::Diversity::Utils> module contained within this distribution
provides tools for helping with the creation of the array of units and
categories.

=back

=head1 DIAGNOSTICS

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
containing N item(s) while this measure requires at least 1 item(s)

This exception is raised when either method L<measure()> or method
L<measure_per_category()> is called with an empty array as argument.

=back

=head1 DEPENDENCIES

This module is part of the Lingua::Diversity distribution, and extends
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

