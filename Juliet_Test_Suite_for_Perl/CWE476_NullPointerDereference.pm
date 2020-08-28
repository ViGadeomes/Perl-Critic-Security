package CWE476_NullPointerDereference;

use strict;
use warnings;

our $VERSION = 1.0;

#needs good one
sub GOOD1()
{
	$value = 18;
	$valuer = \$value;

	return $$valuer;
}

sub BAD1()
{
	$value = 18;
	$valuer = \$value;

	undef $valuer;

	return $$valuer;
}

sub BAD2()
{

	$value = 18;
	$valuer = \$value;

	#After some executions of the loop, we arrive at a point where the reference is dereferenced and still used in next iterations of the loop
	$i = 0;
	
	while($i<=10)
	{
		$age = $$valuer;
		$i++;
		if($i==5)
		{
			undef $valuer;
		}
	}

	return $age;
}

1;