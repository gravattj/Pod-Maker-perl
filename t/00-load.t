#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Pod::Maker' ) || print "Bail out!\n";
}

diag( "Testing Pod::Maker $Pod::Maker::VERSION, Perl $], $^X" );
