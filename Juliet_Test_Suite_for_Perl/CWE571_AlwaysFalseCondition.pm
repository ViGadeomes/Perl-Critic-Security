package CWE571_AlwaysFalseCondition;

use strict;
use warnings;

our $VERSION = 1.0;

sub BAD1()
{
	my $true = 5;
	if(5 != 5)
	{
		return 1;
	}
}

sub BAD2()
{
	$true = 5;
	if($true != $true)
	{
		return 1;
	}
}

sub BAD3()
{
	my $true = 4;
	if(($true+1) != 5)
	{
		return 1;
	}
}

sub BAD4() {
	if(0)
	{
		return 0;
	}
}

1;