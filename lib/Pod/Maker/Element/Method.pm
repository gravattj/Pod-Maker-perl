package Pod::Maker::Element::Method;

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Data::Printer alias => 'pdump';
use Data::Dumper;
use Method::Signatures;
use String::Util qw(hascontent trim);
use Devel::Confess;
use Pod::Maker::Element::Comment;
use Text::Table;
use Pod::Maker::Format;

extends 'Pod::Maker::Element';

################

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

around 'name' => sub {
    my $orig = shift;
    my $self = shift;

    if (@_) {
        my $val = shift @_;
        $val = 'new' if $val eq 'BUILD';
        return $self->$orig($val);
    }
    else {
        return $self->$orig;
    }

};

has classname => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has comment => (
    is  => 'rw',
    isa => 'Pod::Maker::Element::Comment|Undef',
);

has signature => (
    is  => 'rw',
    isa => 'Str',
);

################

method get_pod_paragraph(Int $depth = 2) {

    my $pod = pod_head( depth => $depth, text => $self->name);
    
    if ($self->comment) {
        $pod.= pod_text($self->comment->get_string);     
    }
    
    $pod .= pod_head( depth => $depth +1, text  => 'parameters');
    
    if ( $self->signature ) {
        $pod .= pod_codify($self->_beautify_signature);
    }
    else {
       if ( $self->name eq 'new' ) {
           $pod.= pod_text("see ATTRIBUTES");
        }
        else {
           $pod.= pod_text("none");
        }
    }

    return pod_finalize_paragraph($pod);
}

method _beautify_signature {

    my $sig =
        Method::Signatures::Signature->new(
        signature_string => $self->signature );

    my $tb = Text::Table->new();

    my $aref = $sig->parameters();

    foreach my $param (@$aref) {

        my $p;
        $p = ':' if $param->is_named;
        $p .= $param->variable;
        $p .= '!', if $param->is_required;

        my $default = '';
        if ( $param->default ) {
            $default = sprintf "= %s", trim( $param->default );
        }

        $tb->load( [ $param->type, $p, $default, ] );
    }

    return $tb->stringify;
}

__PACKAGE__->meta->make_immutable;    # moose stuff

1;
