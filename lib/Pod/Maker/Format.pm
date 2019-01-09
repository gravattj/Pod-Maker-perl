package Pod::Maker::Format;

use Exporter::Easy (
    EXPORT => [qw/
        pod_codify 
        pod_head 
        pod_text 
        pod_finalize_paragraph/],
    TAGS => [ all => [qw/
        pod_codify 
        pod_head 
        pod_text pod_
        pod_finalize_paragraph/] ]
);

use Modern::Perl;
use Data::Printer;
use Data::Dumper;
use String::Util qw(hascontent trim);
use Devel::Confess;
use warnings 'FATAL' => 'all';

################

sub pod_codify {

    my ($text) = @_;
    
    my @ret;
    foreach my $t ( split( /\n/, $text ) ) {

        push @ret, "  $t";
    }

    return join( "\n", @ret );
}

sub pod_head {

    my %a = @_;
    my $depth = $a{depth};
    my $text = $a{text};
    
    return sprintf "\n=head%s $text\n\n", $depth;
}

sub pod_text {

    my ($text) = @_;
    
    return "$text\n";
}

sub pod_finalize_paragraph {

    my ($pod) = @_;
    
    $pod = trim($pod);

    if ( $pod =~ /=cut$/ ) {

        return "$pod\n\n";
    }
    else {
        return "$pod\n\n=cut\n\n";
    }
}

1;
