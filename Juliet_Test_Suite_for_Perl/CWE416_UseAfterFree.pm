package CWE416_UseAfterFree;

use strict;
use warnings;

our $VERSION = 1.0;


sub GOOD1()
{

	$value = 'eleven';
	$valuer = \$value;

	#we dereference the reference after it is used
	undef $value;
	$age = $$valuer;

	return $age;
}

sub BAD1()
{

	$value = 'eleven';
	$valuer = \$value;

	#we dereference the reference even before it is used
	undef $value;
	$age = $$valuer;

	return $age;
}

sub GOOD2()
{

	$value = 'eleven';
	$valuer = \$value;

	#After some executions of the loop, we arrive at a point where the reference is dereferenced and still used in next loops
	if(1)
	{
		$age = $$valuer;
	}
	else
	{
		undef $$valuer;
	}

	return $age;
}

sub BAD2()
{

	$value = 'eleven';
	$valuer = \$value;

	#After some executions of the loop, we arrive at a point where the reference is dereferenced and still used in next loops
	$i = 0;
	while($i<=10)
	{
		$age = $$valuer;
		$i++;
		if($i==5)
		{
			undef $$valuer;
		}
	}

	return $age;
}
#Need to implement things with next and last
1;