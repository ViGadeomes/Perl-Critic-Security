package CWE369_DivideByZero;

use strict;
use warnings;

our $VERSION = 1.0;

sub BAD1() {
	my $variable = 5/0;
	return $variable;
}

sub BAD2() {
	my $variable = 0;
	my $variableDivided = 8/$variable;
}

sub BAD3()
{
	my $variable = 5;
	my $diviser = 0;
	
	if($variable/$diviser < 1)
	{
		return 1;
	}
	elsif($variable/$diviser == 1)
	{
		return 0;
	}
	else
	{
		return -1;
	}
}

1;