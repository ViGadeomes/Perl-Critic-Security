package CWE20_noVerificationOfIntegerBeforeUsingIt;

use strict;
use warnings;

our $VERSION = 1.0;

# in a case where we have to ask how many product that we sell the consumer wants, it's better for us to verify his inputs before calculating the total that he needs to give us in exchange.
sub BAD1() {
	$number = <>;
	$price = 4.3;
	print 'How many product do you want ?';
	chomp $number;

	# No verification, the program could end to us having to give him money if he enters a negative value
	$total = $number * $price;

	return $total;
}

sub GOOD1() {
	$number = <>;
	$price = 4.3;
	print 'How many product do you want ';
	chomp $number;

	# Fix with a verification
	if($number >= 0) {
		$total = $number * $price;
	}

	return $total;
}

sub BAD2() {
	$number = <ARGV>;
	$price = 4.3;
	print 'How many product do you want ? ';
	chomp $number;

	# No verification, the program could end to us having to give him money if he enters a negative value
	$total = $number * $price;

	return $total;
}

sub GOOD2() {
	$number = <ARGV>;
	$price = 4.3;
	print 'How many product do you want ?';
	chomp $number;

	# Fix with a verification
	if($number >= 0) {
		$total = $number * $price;
	}

	return $total;
}

sub BAD3() {
	$number = <>;
	$price = 4.3;
	$total = 0;

	# We created a loop that will end when the consumer will enter a non negative value no matter if it's a negative or a positive one
	while($number == 0){
		print 'How many product do you want ?';
		chomp $number;
		$total = $number * $price;
	}
	
	return $total;
}

sub GOOD3() {
	$number = <>;
	$price = 4.3;

	# We created a loop that will end when the consumer will enter an acceptable value
	while($number >= 0){
		print 'How many product do you want ?';
		chomp $number;
	}

	$total = $number * $price;

	return $total;
}

sub BAD4() {
	$price = 4.3;
	$total = 0;

	print 'How many product do you want ?';
	
	# If a lot of consumer want to pay together
	while($number = <ARGV>){
		# No verification
		$total = $total + $number * $price;

		print'How many product do you want ?';
	}

	return $total;
}

sub GOOD4() {
	$number = <ARGV>;
	$price = 4.3;
	$total = 0;

	print 'How many product do you want ?';

	# If a lot of consumer want to pay together
	while($number){
		# A verification of the number entered
		if($number >= 0) {
			$total = $total + $number * $price;
		}

		print("How many product do you want ? ");
	}

	return $total;
}

1;