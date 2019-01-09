package Pod::Maker;

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Data::Printer;
use Data::Dumper;
use Method::Signatures;
use Module::Load;
use String::Util qw(hascontent trim crunch rtrim no_space);
use Pod::Maker::Element::Comment;
use Pod::Maker::Element::Attribute;
use Pod::Maker::Element::Method;
use File::Basename;
use Pod::Maker::Format ':all';

our $VERSION = '0.01';

#
# DESCRIPTION
#
# Automatic pod generator using class introspection and simple comment rules.
#  You may want to use this just to generate your initial pod or as a basis
# for all your pod.  If you have no comments in your code, this will still generate an
# outline.
#
# Formatting your comments to comply with this modules conventions:
#
#   * Header blocks are an isolated comment with one of these keywords:
#
#     * NAME
#     * DESCRIPTION
#     * SYNOPSIS
#
#     * example:
#       #
#       # NAME
#       #
#       # Foo::Bar
#       #
#
#   * Header blocks must have at least one blank line between them.
#
#   * Method comments are directly above method names.  In order to qualify as
#     a method comment, it must be directly above the method and contigous.
#     Additionally, it can't qualify as a header.
#
#     * example:
#       #
#       # Some text you want to include.
#       #
#       #   This is a code block.
#       #
#
#   * Lines with double hashtags (##) are skipped.  Otherwise,this still tries use them.
#
# SYNOPSIS
#
#   my $a = Pod::Maker->new(filename => $filename);
#   $a->parse;
#   $a->write_to_file();
#
#   -or-
#
#   my $pod_string = $a->parse;
#
#   -or-
#
#	use the "podmaker.pl" cli tool that is bundled with this distro.
#

has filename => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has classname => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has comments => (
    is      => 'rw',
    isa     => 'ArrayRef[Pod::Maker::Element::Comment]',
    default => sub { [] }
);

has attributes => (
    is      => 'rw',
    isa     => 'ArrayRef[Pod::Maker::Element::Attribute]',
    default => sub { [] }
);

has methods => (
    is      => 'rw',
    isa     => 'ArrayRef[Pod::Maker::Element::Method]',
    default => sub { [] }
);

has text => (
    is  => 'rw',
    isa => 'ArrayRef',
);

has _parsed => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has _pod => (
    is  => 'rw',
    isa => 'Str',
);

#
# This method parses the perl file.
#
# =head3 usage
#
#   $auto->parse;
#
method parse {

    open( my $fh, '<', $self->filename );
    my @text = <$fh>;
    $self->text( \@text );
    close($fh);

    my $element;

    for ( my $i = 0; $i < scalar @text; $i++ ) {

        my $l = $text[$i];

        next if $l =~ /##/;

        if ( hascontent($l) or $l =~ /#/ ) {

            if ( $l =~ /^\s*package (.+);/ and !$self->classname ) {

                # package
                $self->_handle_package($1);
            }
            elsif ( $l =~ /^\s*#(.*)/
                and !$self->_element_is_method($element) )
            {
               # line is a comment line and we are not in the middle of a method
                $element = $self->_handle_comment(
                    element => $element,
                    line    => $1
                );
            }
            elsif ( $l =~ /^\s*has\s+(\w+) =>/ ) {

                # attribute
                $element =
                    $self->_handle_attribute( element => $element, line => $1 );

            }
            elsif ( $l =~ /^\s*sub\s+(\w+)\s+(\w+)/ ) {

                # sub
                $element = $self->_handle_sub(
                    element => $element,
                    line    => $l,
                    name    => $1,
                );
            }
            elsif ( $l =~ /^\s*method\s+(\w+)/ ) {

                # method
                $element = $self->_handle_method(
                    pos     => $i,
                    element => $element,
                    line    => $1,
                    name    => $1,
                );
            }
            elsif ($element) {

                my $trimmed = rtrim($l);

                if ( $trimmed eq '}' and $element->is_method ) {

                    # this if statement isn't fool proof...
                    $self->_stash_element($element);
                    $element = undef;
                }
            }
        }
    }

    if ($element) {
        $self->_stash_element($element);
    }

    $self->_parsed(1);

    return 1;
}

#
# This method writes the previously parsed .pm to the corresponding .pod file.
#

method write_to_file {

    if ( !$self->_pod ) {
        confess "can't find pod.  did you forget to generate it?";
    }

    my $file = basename( $self->filename );
    $file =~ s/pm$/pod/;
    my $dir = dirname( $self->filename );
    my $fullpath = sprintf '%s/%s', $dir, $file;

    open( my $fh, '>', $fullpath )
        or confess "failed to open file $fullpath: $!";
    print $fh $self->_pod;

    return 1;
}

method generate_pod {

    if ( !$self->_parsed ) {
        $self->_parse;
    }

    my $pod = $self->_print_name;
    $pod .= $self->_get_header_blocks;
    $pod .= $self->_get_inherits_block;
    $pod .= $self->_print_attributes;
    $pod .= $self->_print_methods;

    return $self->_pod($pod);
}

method _element_is_method ($element) {

    if ($element) {

        if ( $element->is_method ) {
            return 1;
        }
    }

    return 0;
}

method _get_header_blocks {

    my $pod = '';

    foreach my $comm ( @{ $self->comments } ) {

        if ( $comm->is_header ) {
            $pod .= $comm->get_pod_paragraph;
        }
    }

    return $pod;
}

method _handle_package (Str $str!) {

    $self->classname($1);
}

method _get_inherits_block {

    my $pod = '';
    my $meta;
    eval { $meta = $self->classname->meta; };

    if ( !$@ ) {
        my @parents = $meta->superclasses;

        if (@parents) {
            $pod = pod_head( depth => 1, text => 'INHERITS FROM' );
            $pod .= pod_text( join( "\n", sort @parents ) );
            $pod = pod_finalize_paragraph($pod);
        }
    }
    else {
        # TODO non-moose module
    }

    return $pod;
}

method _print_name {

    my $pod = pod_head( depth => 1, text => 'NAME' );
    $pod .= pod_text( $self->classname );
    $pod = pod_finalize_paragraph($pod);

    return $pod;
}

method _new_comment ($line!) {

    my $comment = Pod::Maker::Element::Comment->new;
    $comment->append_string($line);

    return $comment;
}

method _new_attribute ($name!) {

    return Pod::Maker::Element::Attribute->new(
        name      => $name,
        classname => $self->classname
    );
}

method _new_method (Str :$name!) {

    return Pod::Maker::Element::Method->new(
        name      => $name,
        classname => $self->classname,
    );
}

method _stash_element (Pod::Maker::Element $element!) {

    if ( $element->is_comment ) {
        $self->_stash_comment($element);
    }
    elsif ( $element->is_attribute ) {
        $self->_stash_attribute($element);
    }
    elsif ( $element->is_method ) {
        $self->_stash_method($element);
    }
    else {
        confess;
    }
}

method _stash_method (Pod::Maker::Element::Method $method!) {

    my $aref = $self->comments;

    if (@$aref) {

        my $comment = pop(@$aref);

        if ( !$comment->is_header ) {
            $method->comment($comment);
        }
        else {
            # put the comment back
            push @$aref, $comment;
        }

        $self->comments($aref);
    }

    push @{ $self->methods }, $method;
}

method _stash_attribute (Pod::Maker::Element::Attribute $attribute!) {

    push @{ $self->attributes }, $attribute;
}

method _stash_comment (Pod::Maker::Element::Comment $comment!) {

    if ( !$comment->is_blank ) {
        push @{ $self->comments }, $comment;
    }
}

method _handle_comment (:$element, :$line) {

    my $comment;

    if ( !$element ) {

        $comment = $self->_new_comment($line);
    }
    elsif ( $element->is_comment ) {

        $comment = $element;

        if ( $comment->is_header_line($line) ) {

            # stash comment and start a new comment
            $self->_stash_comment($comment);
            $comment = $self->_new_comment($line);
        }
        else {
            $comment->append_string($line);
        }
    }
    else {
        # stash element and start a new comment
        $self->_stash_element($element);
        $comment = $self->_new_comment($line);
    }

    return $comment;
}

method _handle_sub (
    :$name!, 
    Pod::Maker::Element|Undef :$element, 
    :$line) {

    $line = trim($line);

    $self->_stash_element($element) if $element;
    my $method = $self->_new_method( name => $line );

    return $method;
}

method _handle_method (
    :$name!, 
    :$pos!, 
    Pod::Maker::Element|Undef :$element, 
    :$line) {

    $line = trim($line);

    $self->_stash_element($element) if $element;
    my $method = $self->_new_method( name => $line );

    if ( $self->text->[$pos] =~ /\(/ ) {

        # we have a Method::Signature

        my @sig = $self->_read_ahead( start => $pos, find => qr/\)/ );

        my $sig = join( ' ', @sig );
        $sig =~ s/.+\(//;    # remove (
        $sig =~ s/\).+//;    # remove )
        $sig = crunch($sig); # trim surrounding ws

        $method->signature($sig);
    }

    return $method;

=pod
  
    my $comment;
    if ($element) {
        if ( $element->is_comment ) {
            if ( $element->is_header ) {
                $self->_stash_element($element);
            }
            else {
                $comment = $element;
            }
        }

        $self->_stash_element($element);
    }

    my $method = $self->_new_method( name => $line, comment => $comment );

    if ( $self->text->[$pos] =~ /\(/ ) {

        # we have a Method::Signature

        my @sig = $self->_read_ahead( start => $pos, find => qr/\)/ );

        my $sig = join( ' ', @sig );
        $sig =~ s/.+\(//;    # remove (
        $sig =~ s/\).+//;    # remove )
        $sig = crunch($sig); # trim surrounding ws

        $method->signature($sig);
    }

    return $method;
    
=cut

}

method _read_ahead (:$start, :$find) {

    my @ret;
    my $text = $self->text;

    for ( my $i = $start; $i < @$text; $i++ ) {

        push @ret, $text->[$i];
        last if $text->[$i] =~ $find;
    }

    confess if !@ret;

    return @ret;
}

method _handle_attribute (:$element, :$line) {

    $line = trim($line);

    my $attr;

    if ( !$element ) {

        $attr = $self->_new_attribute($line);
    }
    elsif ( $element->is_attribute ) {

        $attr = $element;

        $self->_stash_attribute($attr);
        $attr = $self->_new_attribute($line);
    }
    else {
        # stash element and start a new comment
        $self->_stash_element($element);
        $attr = $self->_new_attribute($line);
    }

    return $attr;
}

method _print_methods {

    my $pod = pod_head( depth => 1, text => 'METHODS' );

    my %methods;

    foreach my $method ( @{ $self->methods } ) {

        next if $method->name =~ /^_/;

        $methods{ $method->name } = $method;
    }

    my @ret;
    foreach my $key ( sort keys %methods ) {
        my $method = $methods{$key};
        $pod .= $method->get_pod_paragraph;
    }

    return $pod;
}

method _print_required_attributes {

    my @attr = $self->_get_required_attributes;
    my $pod = pod_head( depth => 2, text => 'REQUIRED' );

    if (@attr) {
        foreach my $attr (@attr) {

            next if $attr->name =~ /^_/;
            next if !$attr->is_required;

            $pod .= $attr->get_pod_paragraph( depth => 3 );
        }
    }
    else {
        $pod .= pod_text("none");
        $pod = pod_finalize_paragraph($pod);

    }

    return $pod;
}

method _print_optional_attributes {

    my @attr = $self->_get_optional_attributes;
    my $pod = pod_head( depth => 2, text => 'OPTIONAL' );

    if (@attr) {
        foreach my $attr (@attr) {

            next if $attr->name =~ /^_/;
            next if $attr->is_required;

            $pod .= $attr->get_pod_paragraph( depth => 3 );
        }
    }
    else {
        $pod .= pod_text("none");
        $pod = pod_finalize_paragraph($pod);
    }

    return $pod;
}

method _print_attributes {

    my $pod = pod_head( depth => 1, text => 'ATTRIBUTES' );
    $pod .= $self->_print_required_attributes;
    $pod .= $self->_print_optional_attributes;

    return $pod;
}

method _get_optional_attributes {

    my %opt;

    foreach my $attr ( @{ $self->attributes } ) {

        my $name = $attr->name;
        if ( $name !~ /^_/ and !$attr->is_required ) {
            $opt{$name} = $attr;
        }
    }

    my @ret;
    foreach my $key ( sort keys %opt ) {
        push @ret, $opt{$key};
    }

    return @ret;
}

method _get_required_attributes {

    my %opt;

    foreach my $attr ( @{ $self->attributes } ) {

        my $name = $attr->name;
        if ( $name !~ /^_/ and $attr->is_required ) {
            $opt{$name} = $attr;
        }
    }

    my @ret;
    foreach my $key ( sort keys %opt ) {
        push @ret, $opt{$key};
    }

    return @ret;
}

__PACKAGE__->meta->make_immutable;    # moose stuff

1;
