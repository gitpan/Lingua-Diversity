#!/usr/bin/perl

package Lingua::Diversity::Utils;

use strict;
use warnings;
use Carp;

use Exporter   ();

our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(
    split_text
    split_tagged_text
);

our $VERSION     = 0.02;

use Lingua::Diversity::X;


#=============================================================================
# Subroutines
#=============================================================================

#-----------------------------------------------------------------------------
# Subroutine split_text
#-----------------------------------------------------------------------------
# Synopsis:      Split a text into units, delete empty units, and return a
#                reference to the array of units.
# Parameters:    - text (required): a reference to the string to be split.
#                - regexp:          a regular expression describing unit
#                                   delimiter sequences.
# Return values: - A reference to an array of units.
#-----------------------------------------------------------------------------

sub split_text {
    my ( %parameter ) = @_;

    # Parameter 'text' is required...
    Lingua::Diversity::X::Utils::SplitTextMissingParam->throw()
        if ! exists $parameter{'text'};

    # Default regexp parameter is any sequence of blanks.
    $parameter{'regexp'} ||= qr{\s+};

    # Split text with regexp.
    my @array = split $parameter{'regexp'}, ${ $parameter{'text'} };

    # Delete empty elements.
    @array = grep { $_ } @array;

    # Return a reference to the array of units.
    return \@array;
}


#-----------------------------------------------------------------------------
# Subroutine split_tagged_text
#-----------------------------------------------------------------------------
# Synopsis:      Given a Lingua::TreeTagger::TaggedText object, return a
#                reference to the array of units (e.g. wordforms). Optionally,
#                return a second reference to the array of categories
#                (e.g. lemmas).
# Parameters:    - taggged_text (required): a Lingua::TreeTagger::TaggedText.
#                - unit (required):         'original', 'lemma', or 'tag'.
#                - category:                'lemma', or 'tag'.
# Return values: - A reference to an array of units.
#                - An optional reference to an array of categories.
#-----------------------------------------------------------------------------

sub split_tagged_text {
    my ( %parameter ) = @_;

    # Parameter 'unit' is required...
    Lingua::Diversity::X::Utils::SplitTaggedTextMissingUnitParam->throw()
        if ! exists $parameter{'unit'};

    # Parameter 'unit' must be either 'original', 'lemma', or 'tag'...
    Lingua::Diversity::X::Utils::SplitTaggedTextWrongUnitParam->throw()
        if $parameter{'unit'} ne 'original'
        && $parameter{'unit'} ne 'lemma'
        && $parameter{'unit'} ne 'tag';

    # Parameter 'tagged_text' is required...
    Lingua::Diversity::X::Utils::SplitTaggedTextMissingTaggedTextParam->throw()
        if ! exists $parameter{'tagged_text'};

    # Parameter 'tagged_text' must be a Lingua::TreeTagger::TaggedText...
    Lingua::Diversity::X::Utils::SplitTaggedTextWrongTaggedTextParamType->throw()
        if ref( $parameter{'tagged_text'} )
           ne 'Lingua::TreeTagger::TaggedText';

    my @units;

    # If parameter 'category' is provided...
    if ( exists $parameter{'category'} ) {

        # Parameter 'category' must be either 'lemma' or 'tag'...
        Lingua::Diversity::X::Utils::SplitTaggedTextWrongCategoryParam->throw()
            if $parameter{'category'} ne 'lemma'
            && $parameter{'category'} ne 'tag';
            
        my @categories;
        
        TOKEN:
        foreach my $token ( @{ $parameter{'tagged_text'}->sequence() } ) {

            # Skip SGML tags.
            next TOKEN if $token->is_SGML_tag();

                     # Unit param value...              # Token attribute...
            my $unit = $parameter{'unit'} eq 'original' ? $token->original()
                     : $parameter{'unit'} eq 'lemma'    ? $token->lemma()
                     :                                    $token->tag()
                     ;

            # Add unit to array.
            push @units, $unit;

                         # Category param value...       # Token attribute...
            my $category = $parameter{'unit'} eq 'lemma' ? $token->lemma()
                         :                                 $token->tag()
                         ;

            # Add category to array.
            push @categories, $category;
        }
        
        # Return refs to both arrays.
        return \@units, \@categories;
    }

    # Otherwise, if no parameter 'category' is provided...
    
    TOKEN:
    foreach my $token ( @{ $parameter{'tagged_text'}->sequence() } ) {

        # Skip SGML tags.
        next TOKEN if $token->is_SGML_tag();

                 # Unit param value...              # Token attribute...
        my $unit = $parameter{'unit'} eq 'original' ? $token->original()
                 : $parameter{'unit'} eq 'lemma'    ? $token->lemma()
                 :                                    $token->tag()
                 ;

        # Add unit to array.
        push @units, $unit;
    }

    # Return ref to unit array.
    return \@units;
}


1;


__END__


=head1 NAME

Lingua::Diversity::Utils - utility subroutines for users of classes
derived from L<Lingua::Diversity>

=head1 VERSION

This documentation refers to Lingua::Diversity::Utils version 0.02.

=head1 SYNOPSIS

    use Lingua::Diversity::Utils qw( split_text split_tagged_text );

    my $text = 'of the people, by the people, for the people';

    # Get a reference to an array of words...
    my $word_array_ref = split_text(
        'text'      => \$text,
        'regexp'    => qr{[^a-zA-Z]+},
    );

    # Alternatively, tag the text using Lingua::TreeTagger...
    use Lingua::TreeTagger;
    my $tagger = Lingua::TreeTagger->new(
        'language' => 'english',
        'options'  => [ qw( -token -lemma -no-unknown ) ],
    );
    my $tagged_text = $tagger->tag_text( \$text );

    # ... get a reference to an array of words...
    $word_array_ref = Lingua::Diversity::Utils->split_tagged_text(
        'tagged_text'   => $tagged_text,
        'unit'          => 'original',
    );

    # ... or get a reference to an array of wordforms and an array of lemmas.
    ( $wordform_array_ref, $lemma_array_ref )= split_tagged_text(
        'tagged_text'   => $tagged_text,
        'unit'          => 'original',
        'category'      => 'lemma',
    );



=head1 DESCRIPTION

This module provides utility subroutines intended to facilitate the
use of a class derived from L<Lingua::Diversity>.

=head1 SUBROUTINES

=over 4

=item split_text()

Split a text into units (typically words), delete empty units, and return a
reference to the array of units.

The subroutine requires one named parameter and may take up to two of them.

=over 4

=item text (required)

A reference to the text to be split.

=item regexp

A reference to a regular expression describing unit delimiter sequences.
Default is C<qr{\s+}>.

=back

=item split_tagged_text()

Given a L<Lingua::TreeTagger::TaggedText> object, return a reference to the
array of units (e.g. wordforms). Optionally, return a second reference to the
array of categories (e.g. lemmas).

The subroutine requires two named parameters and may take up to three of them.

=over 4

=item tagged_text (required)

The Lingua::TreeTagger::TaggedText object to be split.

=item unit (required)

The L<Lingua::TreeTagger::Token> attribute (either 'original', 'lemma', or
'tag') that should be used to build the unit array. NB: make sure the
requested attribute is available in the L<Lingua::TreeTagger::TaggedText>
object!

=item category

The L<Lingua::TreeTagger::Token> attribute (either 'lemma' or 'tag') that
should be used to build the category array. NB: make sure the requested
attribute is available in the L<Lingua::TreeTagger::TaggedText> object!

=back

=back

=head1 DIAGNOSTICS

=over 4

=item Missing parameter 'text' in call to subroutine C<split_text()>

This exception is raised when subroutine C<split_text()> is called without a
parameter named 'text' (whose value should be a reference to a string).

=item Missing parameter 'tagged_text' in call to subroutine
C<split_tagged_text()>

This exception is raised when subroutine C<split_tagged_text()> is called
without a parameter named 'tagged_text').

=item Parameter 'tagged_text' in call to subroutine C<split_tagged_text()>
must be a L<Lingua::TreeTagger::TaggedText> object

This exception is raised when subroutine C<split_tagged_text()> is called
with a parameter named 'tagged_text' whose value is not a
L<Lingua::TreeTagger::TaggedText> object.

=item Missing parameter 'unit' in call to subroutine C<split_tagged_text()>

This exception is raised when subroutine C<split_tagged_text()> is called
without a parameter named 'unit').

=item Parameter 'unit' in call to subroutine C<split_tagged_text()> must be
either 'original', 'lemma', or 'tag'

This exception is raised when subroutine C<split_tagged_text()> is called
with a parameter named 'unit' whose value is not 'original', 'lemma', or
'tag'.

=item Parameter 'category' in call to subroutine C<split_tagged_text()> must
be either 'lemma' or 'tag'

This exception is raised when subroutine C<split_tagged_text()> is called
with a parameter named 'category' whose value is not 'lemma' or 'tag'.

=back

=head1 DEPENDENCIES

This module is part of the L<Lingua::Diversity> distribution. Some subroutines
are designed to operate on L<Lingua::TreeTagger::TaggedText> objects.

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

L<Lingua::Diversity>, L<Lingua::TreeTagger>.

