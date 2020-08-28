package CWE478_MissingDefaultInGivenStatement;

use strict;
use warnings;

our $VERSION = 1.0;


sub GOOD1()
{
	my $color;
	chomp($color);
	$color = uc($color);

	given($color){

		 when ('RED') {  $code = '#FF0000'; }

		 when ('GREEN') {  $code = '#00FF00'; }

		 when ('BLUE') {  $code = '#0000FF'; }

		 default{
			 $code = '';
		 }
	}

  return $code;
}

sub BAD1()
{
	my $color;
	chomp($color);
	$color = uc($color);

	given($color){

		 when ('RED') {  $code = '#FF0000'; }

		 when ('GREEN') {  $code = '#00FF00'; }

		 when ('BLUE') {  $code = '#0000FF'; }
	}

  return $code;
}

1;