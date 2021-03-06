# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.040.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Simple logger",
  "AUTHOR" => "Dan Book <dbook\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Log-Emitter",
  "LICENSE" => "artistic_2",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Log::Emitter",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Class::Method::Modifiers" => 0,
    "Class::Tiny::Chained" => 0,
    "Encode" => 0,
    "Fcntl" => 0,
    "IO::Handle" => 0,
    "Role::EventEmitter" => "0.002",
    "Role::Tiny::With" => "2.000001"
  },
  "TEST_REQUIRES" => {
    "File::Spec::Functions" => 0,
    "File::Temp" => 0,
    "Test::More" => "0.88"
  },
  "VERSION" => "0.005",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Class::Method::Modifiers" => 0,
  "Class::Tiny::Chained" => 0,
  "Encode" => 0,
  "Fcntl" => 0,
  "File::Spec::Functions" => 0,
  "File::Temp" => 0,
  "IO::Handle" => 0,
  "Role::EventEmitter" => "0.002",
  "Role::Tiny::With" => "2.000001",
  "Test::More" => "0.88"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
