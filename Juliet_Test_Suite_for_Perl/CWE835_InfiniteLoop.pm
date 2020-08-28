package CWE835_InfiniteLoop;

use strict;
use warnings;

our $VERSION = 1.0;
#/Needs GOOD ones and/ tests with next and last.
sub GOOD1(){
	my $total = 0;

	while(1)
	{
		$total = $total++;
		last if($total == 22);
	}

	return $total;
}

sub BAD1(){
	my $total = 0;

	while(1)
	{
		$total = $total++;
	}

	return $total;
}

sub GOOD2(){
	my $total = 0;

	while($total >= 0)
	{
		$total = $total++;
		last if(total >= 10);
	}

	return $total;
}

sub BAD2(){
	my $total = 0;

	while($total >= 0)
	{
		$total = $total++;
	}

	return $total;
}

sub GOOD3(){
	my $total = 0;

	until(0)
	{
		$total = $total++;
		last if($total == 32);
	}

	return $total;
}

sub BAD3(){
	my $total = 0;

	until(0)
	{
		$total = $total++;
	}

	return $total;
}

sub GOOD4(){
	my $total = 0;

	until($total < 0)
	{
		$total = $total++;
		last if($total > 30);
	}

	return $total;
}

sub BAD4(){
	my $total = 0;

	until($total < 0)
	{
		$total = $total++;
	}

	return $total;
}

sub GOOD5(){
	my $total = 0;

	loop_label:{
		do
		{
			$total = $total++;
			last if(total == 22);
		} while(1);
	}

	return $total;
}

sub BAD5(){
	my $total = 0;

	do
	{
		$total = $total++;
	} while(1);

	return $total;
}

sub GOOD6(){
	my $total = 0;

	last:{
		do
		{
			$total = $total++;
			last if($total < 18);
		} while($total > 0);
	}

	return $total;
}

sub BAD6(){
	my $total = 0;

	do
	{
		$total = $total++;
	} while($total > 0);

	return $total;
}

sub GOOD7(){
	my $total = 0;

	last:{
		do
		{
			$total = $total++;
			last if($total == 32);
		} until(0);
	}

		return $total;
}

sub BAD7(){
	my $total = 0;

	do
	{
		$total = $total++;
	} until(0);

	return $total;
}

sub GOOD8(){
	my $total = 0;

	last:{
		do
		{
			$total = $total++;
		} until($total <= 0);
	}

	return $total;
}

sub BAD8(){
	my $total = 0;

	do
	{
		$total = $total++;
	} until($total >= 0);

	return $total;
}

sub GOOD9(){
	my $total = 0;

	for(;;)
	{
		$total = $total++;
		last if($total == 10);
	}

	return $total;
}

sub BAD9(){
	my $total = 0;

	for(;;)
	{
		$total = $total++;
	}

	return $total;
}

sub GOOD10(){
	my $total = 0;

	for(my $i = 0; $i >= 0; $i++)
	{
		$total = $total++;
		last if($i == 20);
	}

	return $total;
}

sub BAD10(){
	my $total = 0;

	for(my $i = 0; $i >= 0; $i++)
	{
		$total = $total++;
	}

	return $total;
}

sub BAD11(){
	my $total = 0;

	for(my $i = 0; $i >= 0; $i++)
	{
		$total = $total++;
		next if($i == 20);
		last if($i == 20);
	}

	return $total;
}

sub GOOD11(){
	my $total = 0;

	for(my $i = 0; $i >= 0; $i++)
	{
		$total = $total++;
		last if($i == 20);
		next if($i == 20);
	}

	return $total;
}
1;