#!/usr/bin/env perl

###### PACKAGES ######

use Modern::Perl;
use Getopt::Long::Descriptive;
use Data::Dumper;
use Data::Printer;
use Pod::Maker;
use File::Find::Rule;

###### PACKAGE CONFIG ######

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 1;

###### CONSTANTS ######

###### GLOBALS ######

use vars qw(
    $Dir
    $File
);

###### MAIN ######

parse_cmd_line();

my @files;

if ($Dir) {

    # find all the .pm files in $Dir
    @files = File::Find::Rule->file()->name('*.pm')->in($Dir);
}
else {
    push @files, $File;
}

foreach my $file (@files) {

    my $auto = Pod::Maker->new(filename => $file);
    $auto->parse;
    $auto->generate_pod();
    $auto->write_to_file();
}

###### END MAIN ######

sub parse_cmd_line {

    my @tmp = @ARGV;

    my ( $opt, $usage ) = describe_options(
        '%c %o>',
        [ 'd=s', "dir to scan for pm files" ],
        [ 'f=s', "file to use" ],
        [ 'help|?', "print usage message and exit", { shortcircuit => 1 } ],
    );

    if ( $opt->{help} ) {
        say $usage->text;
        exit 1;
    }

    $Dir  = $opt->d if $opt->d;
    $File = $opt->f if $opt->f;

    if ( !$File and !$Dir ) {
        say "must provide -d or -f";
        say $usage->text;
        exit 1;
    }

    if ( $File and $Dir ) {
        say "can't specify both -d and -f";
        say $usage->text;
        exit 1;
    }

    @ARGV = @tmp;
}

