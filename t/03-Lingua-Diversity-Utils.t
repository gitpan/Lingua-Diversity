#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

# Module is usable...
BEGIN {
    use_ok( 'Lingua::Diversity::Utils', qw(
        split_text
        split_tagged_text
    ) )
      || print "Bail out!\n";
}

# Subroutine split_text requires parameter 'text'...
eval { split_text() };
is(
    ref $@,
    'Lingua::Diversity::X::Utils::SplitTextMissingParam',
    'Subroutine split_text() correctly croaks when called without '
 . q{parameter 'text'}
);

my $text = 'of the people, by the people, for the people';

# Get a reference to an array of words...
my $word_array_ref = split_text(
    'text'      => \$text,
    'regexp'    => qr{[^a-zA-Z]+},
);

# Subroutine split_text() correctly splits text...
ok(
       $word_array_ref->[0] eq 'of'
    && $word_array_ref->[1] eq 'the'
    && $word_array_ref->[2] eq 'people'
    && $word_array_ref->[3] eq 'by'
    && $word_array_ref->[4] eq 'the'
    && $word_array_ref->[5] eq 'people'
    && $word_array_ref->[6] eq 'for'
    && $word_array_ref->[7] eq 'the'
    && $word_array_ref->[8] eq 'people',
    'Subroutine split_text() correctly splits text'
);

# Subroutine split_tagged_text requires parameter 'unit'...
eval { split_tagged_text() };
is(
    ref $@,
    'Lingua::Diversity::X::Utils::SplitTaggedTextMissingUnitParam',
    'Subroutine split_tagged_text() correctly croaks when called without '
 . q{parameter 'unit'}
);

# Parameter 'unit' must be either 'original', 'lemma', or 'tag'...
eval { split_tagged_text( 'unit' => 'word' ) };
is(
    ref $@,
    'Lingua::Diversity::X::Utils::SplitTaggedTextWrongUnitParam',
    'Subroutine split_tagged_text() correctly croaks when called with '
 . q{illegal value for parameter 'unit'}
);

# Subroutine split_tagged_text requires parameter 'tagged_text'...
eval { split_tagged_text( 'unit' => 'original' ) };
is(
    ref $@,
    'Lingua::Diversity::X::Utils::SplitTaggedTextMissingTaggedTextParam',
    'Subroutine split_tagged_text() correctly croaks when called without '
 . q{parameter 'tagged_text'}
);

# Parameter 'tagged_text' must be a Lingua::TreeTagger::TaggedText...
eval {
    split_tagged_text(
        'unit'          => 'original',
        'tagged_text'   => 1,
    )
};
is(
    ref $@,
    'Lingua::Diversity::X::Utils::SplitTaggedTextWrongTaggedTextParamType',
    'Subroutine split_tagged_text() correctly croaks when call with a '
 . q{parameter 'tagged_text' that is not a Lingua::TreeTagger::TaggedText}
);

# Parameter 'category' must be either 'lemma' or 'tag'...
my $mock_tagged_text = {};
bless $mock_tagged_text, 'Lingua::TreeTagger::TaggedText';
eval {
    split_tagged_text(
        'unit'          => 'original',
        'tagged_text'   => $mock_tagged_text,
        'category'      => 'root',
    )
};
is(
    ref $@,
    'Lingua::Diversity::X::Utils::SplitTaggedTextWrongCategoryParam',
    'Subroutine split_tagged_text() correctly croaks when called with '
 . q{illegal value for parameter 'category'}
);

SKIP: {
    eval { require Lingua::TreeTagger };

    skip "Lingua::TreeTagger not installed", 2 if $@;

    # Get a tagged text
    my $tagger = Lingua::TreeTagger->new(
        'language' => 'english',
        'options'  => [ qw( -token -lemma -no-unknown ) ],
    );
    my $tagged_text = $tagger->tag_text( \$text );

    # Get a reference to an array of words...
    my $word_array_ref = split_tagged_text(
        'tagged_text'   => $tagged_text,
        'unit'          => 'original',
    );

    # Remove commas...
    @$word_array_ref = grep { $_ ne q(,) } @$word_array_ref;

    # Subroutine split_tagged_text() correctly splits text (1 array)...
    ok(
           $word_array_ref->[0] eq 'of'
        && $word_array_ref->[1] eq 'the'
        && $word_array_ref->[2] eq 'people'
        && $word_array_ref->[3] eq 'by'
        && $word_array_ref->[4] eq 'the'
        && $word_array_ref->[5] eq 'people'
        && $word_array_ref->[6] eq 'for'
        && $word_array_ref->[7] eq 'the'
        && $word_array_ref->[8] eq 'people',
        'Subroutine split_tagged_text() correctly splits text (1 array)'
    );

    # Get a reference to an array of words and an array of POS tags...
    ( $word_array_ref, my $category_array_ref ) = split_tagged_text(
        'tagged_text'   => $tagged_text,
        'unit'          => 'original',
        'category'      => 'tag',
    );

    # Remove commas...
    @$word_array_ref     = grep { $_ ne q(,) } @$word_array_ref;
    @$category_array_ref = grep { $_ ne q(,) } @$category_array_ref;

    # Subroutine split_tagged_text() correctly splits text (2 arrays)...
    ok(
           $word_array_ref->[0]     eq 'of'
        && $word_array_ref->[1]     eq 'the'
        && $word_array_ref->[2]     eq 'people'
        && $word_array_ref->[3]     eq 'by'
        && $word_array_ref->[4]     eq 'the'
        && $word_array_ref->[5]     eq 'people'
        && $word_array_ref->[6]     eq 'for'
        && $word_array_ref->[7]     eq 'the'
        && $word_array_ref->[8]     eq 'people'
        && $category_array_ref->[0] eq 'IN'
        && $category_array_ref->[1] eq 'DT'
        && $category_array_ref->[2] eq 'NNS'
        && $category_array_ref->[3] eq 'IN'
        && $category_array_ref->[4] eq 'DT'
        && $category_array_ref->[5] eq 'NNS'
        && $category_array_ref->[6] eq 'IN'
        && $category_array_ref->[7] eq 'DT'
        && $category_array_ref->[8] eq 'NNS',
        'Subroutine split_tagged_text() correctly splits text (2 arrays)'
    );
}





