package CWE561_DeadCode;

use strict;
use warnings;

our $VERSION = 1.0;

sub BAD1()
{
	my $true = 5;
	if(5 == 5)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

1;