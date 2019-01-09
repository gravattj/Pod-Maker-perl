package Pod::Maker::Element::Comment;

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Data::Printer;
use Data::Dumper;
use Method::Signatures;
use String::Util qw(hascontent trim);
use Devel::Confess;
use Pod::Maker::Format;

extends 'Pod::Maker::Element';

################

has _headers => (
    is       => 'ro',
    isa      => 'ArrayRef',
    default  => sub { [qw(NAME DESCRIPTION SYNOPSIS)] },
    init_arg => undef,
);

has _header => (    # must be one of 'headers'
    is  => 'rw',
    isa => 'Str',
);

has _comment => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

################

method get_header {

    if ( $self->_header ) {

        return $self->_header;
    }
    else {

        my $header = $self->is_header;

        if ($header) {

            $self->_header($header);
            return $self->header;
        }
    }

    confess "comment is not a header type";
}

method get_string {
    return join( "\n", @{ $self->_comment } );
}

method append_string (Str $str = '') {

  #  $str =~ s/^\s*#+//;    # remove leading hashtags
    $str =~ s/^ //;        # remove first and only first space char

    my $header = $self->is_header_line($str);

    if ($header) {
        if ( $self->_header ) {
            confess
                "can't set header because header is already set to "
                . $self->_header;
        }
        else {
            $self->_header($header);
        }
    }
    else {

        push( @{ $self->_comment }, $str );
    }

    return 1;
}

method is_header_line (Str $str!) {

#    $str =~ s/^\s*#+//;    # remove leading hashtags
    $str = trim($str);
    $str = quotemeta($str);  # translate special chars to normal chars for regex

    my @found = grep { /^$str$/ } @{ $self->_headers };

    if ( !@found ) {
        return 0;
    }
    else {
        return $found[0];
    }

    confess;
}

method is_header {

    if ( $self->_header ) {
        return 1;
    }
    else {
        return 0;
    }
}

method is_blank {

    my $line = $self->get_string;

    if ( hascontent($line) ) {
        return 0;
    }

    return 1;
}

method get_pod_paragraph {

    if ( !$self->_header ) {

        confess "can't generate a paragraph because comment is not a header";
    }

    my $pod = pod_head( depth => 1, text => $self->_header );
    $pod .= pod_text( $self->get_string );

    return pod_finalize_paragraph($pod);
}

__PACKAGE__->meta->make_immutable;    # moose stuff

1;
