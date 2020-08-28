package CWE480_WrongOperator;

use strict;
use warnings;

our $VERSION = 1.0;

sub BAD1() {
	my $variable == 56;

  return $variable;
}

sub BAD2() {
	my $variable;
	$variable == 56;

  return $variable;
}

sub BAD3() {
	my $variable;

  return $variable;
}

sub BAD4() 
{
	my $value = 3;
	my $variable = $value++ || 7;

  return $variable;
}

sub BAD5() {
	my $variable = 7;
	if($variable = 8)
	{
		return 0;
	}
	elsif($variable ! 7)
	{
		return 1;
	}
}

sub GOOD5()
{
	my $tring = '';
	while(my $variable = <>)
	{
		$tring = $tring . '  ' . $variable; 
	}
  return $variable;
}

sub BAD6()
{
	my $variable = 7;
	my $tring = 'hello';
	
	if($variable eq 'hello'| $tring == 7)
	{
		return 1;
	}
	else {
		return 0;
	}
}

sub GOOD7()
{
	my variable = 0;
	while(!(($variable + 6) == 13))
	{
		$variable++;
	}

  return $variable;
}

1;