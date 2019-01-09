package Pod::Maker::Element::Attribute;

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Data::Printer;
use Data::Dumper;
use Method::Signatures;
use String::Util qw(hascontent trim);
use Devel::Confess;
use Pod::Maker::Element::Comment;
use Pod::Maker::Format qw(:all);
use Text::Table;

extends 'Pod::Maker::Element';

################

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has classname => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has comment => (
    is  => 'rw',
    isa => 'Pod::Maker::Element::Comment',
);

has _meta => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_meta'
);

################

method get_pod_paragraph (Int :$depth = 2) {

    my $pod = pod_head( depth => $depth, text => $self->name );

    my $meta = $self->_meta;

    if ($meta) {
        my $tb = Text::Table->new();

        $tb->load( [ "is: ",   $meta->{is} ] )   if $meta->{is};
        $tb->load( [ "isa: ",  $meta->{isa} ] )  if $meta->{isa};
        $tb->load( [ "lazy: ", $meta->{lazy} ] ) if $meta->{lazy};

        $pod .= pod_codify( $tb->stringify . "\n" );
    }

    return pod_finalize_paragraph($pod);
}

method is_required {

    if ($self->_meta and $self->_meta->{required} ) {
        return 1;
    }

    return 0;
}

method _build_meta {

    my $meta;
    eval { $meta = $self->classname->meta->get_attribute( $self->name ); };

    return $meta;
}

__PACKAGE__->meta->make_immutable;    # moose stuff

1;
