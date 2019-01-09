package Pod::Maker::Element;

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Data::Printer;
use Data::Dumper;
use Method::Signatures;
use String::Util qw(hascontent trim);
use Devel::Confess;

################

has name => (
    is  => 'rw',
    isa => 'Str',
);

has type => (
    is  => 'rw',
    isa => 'Str',
);

################

method is_comment {

    if ( ref($self) eq 'Pod::Maker::Element::Comment' ) {
        return 1;
    }
}

method is_attribute {

    if ( ref($self) eq 'Pod::Maker::Element::Attribute' ) {
        return 1;
    }
}

method is_method {
   if ( ref($self) eq 'Pod::Maker::Element::Method' ) { 
    return 1;    
   }
}

__PACKAGE__->meta->make_immutable;    # moose stuff

1;
