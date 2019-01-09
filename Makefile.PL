use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Pod::Maker',
    AUTHOR           => q{John Gravatt <gravattj@cpan.org>},
    VERSION_FROM     => 'lib/Pod/Maker.pm',
    ABSTRACT_FROM    => 'lib/Pod/Maker.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    EXE_FILES => [
		"bin/podmaker.pl",
	],
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Pod-Maker-*' },
);
