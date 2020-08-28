package CWE1071_EmptyCodeBlock;

use strict;
use warnings;

our $VERSION = 1.0;

sub BAD1() {




										 


}

sub BAD2() {
	my $tring = 'you';
	
	if($tring != 'you')
	{}
	elsif($tring == 'you') {
	}
	else 
	{
	}
	
	return $tring;
}

sub BAD3()
{
	my $tring = 'you';
	unless($tring != 'you')
	{
		
	}
	return $tring;
}
	
sub BAD4()
{
	my $tring = 'you';
	foreach(my i = 0;i<=5;i++)
	{
	}
	return $tring;
}

sub BAD5()
{
	my $tring = 'you';
	for(my i = 0;i<=10;i++)
	{
	}
	return $tring;
}

sub BAD6()
{
	my $tring = 'you';
	while($tring == 'you')
	{
	}
	return $tring;
}

sub BAD7()
{
	my $tring = 'you';
	until($tring != 'you')
	{}
	return $tring;
}

sub BAD8()
{
	my $tring = 'you';
	given($string){
	}
	return $tring;
}

sub BAD9()
{
	my $tring = 'you';
	given ($string){
		when('you') {
		}
	}
	return $tring;
}

sub BAD10()
{
	my $tring = 'you';
	given ($string){
		default{
		}
	}
	return $tring;
}

sub BAD11()
{
	my $tring = 'you';
	do
	{
	}while($tring == 'you');
	return $tring;
}	

1;