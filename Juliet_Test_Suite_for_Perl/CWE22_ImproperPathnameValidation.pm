package CWEXX_ImproperPathnameValidation;
use strict;
use warnings;

my $path = <>;
print 'PATH: ';
chomp $path;

open(my $file, '>', $path) or die;