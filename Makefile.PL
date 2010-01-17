
use strict;
use warnings;



use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'WWW-Curl-Simple',
  NAME      => 'WWW::Curl::Simple',
  AUTHOR    => "Andreas\ Marienborg\ \<andremar\@cpan\.org\>",
  ABSTRACT  => "A\ Simpler\ interface\ to\ WWW\:\:Curl",
  VERSION   => '0.100171',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Benchmark::Apps" => '0',
    "base" => '0',
    "Scalar::Util" => '0',
    "Test::Exception" => '0',
    "Benchmark" => '0',
    "Carp" => '0',
    "Test::More" => '0',
    "namespace::clean" => '0',
    "HTTP::Response" => '0',
    "File::Basename" => '0',
    "HTTP::Request" => '0',
    "LWP::Simple" => '0',
    "WWW::Curl::Easy" => '0',
    "Moose" => '0',
    "WWW::Curl::Multi" => '0',
  },
  test => {TESTS => 't/*.t'}
);

