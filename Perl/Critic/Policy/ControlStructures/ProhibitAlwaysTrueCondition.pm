package Perl::Critic::Policy::ControlStructures::ProhibitAlwaysTrueCondition;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.138';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Always True Condition};
Readonly::Scalar my $EXPL => q{This condition is always true};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity 	 { return $SEVERITY_HIGH	  }
sub default_themes		 { return qw{core security}   } 
sub applies_to			 { return 'PPI::Structure'  }

#-----------------------------------------------------------------------------

sub violates 
{
	my ($self, $elem, undef) = @_;
 
	return if ( !($elem->isa('PPI::Structure::Condition')) && !($elem->isa('PPI::Structure::For')) ); #We delete cases we dopn't care.
	
	my $element = $elem->first_element();
	
	my @elements = $elem->elements(); #begins with '(' and ends with ')'
  
	my $conditionWord = $elem->parent()->first_token(); #Taking the first element of the condition structure.
  
	if($elem->isa('PPI::Structure::Condition'))
	{
		if( (@elements == 3)) #3 elements
		{
		  if($elements[1]->isa('PPI::Statement::Expression')) #first element is '(' last is ')' and in the middle it is always an expresison
		  {
			if( ($elements[1]->elements() == 1) && (($elements[1]->elements())[0]->isa('PPI::Token::Number')) ) #if only one element which is a number
			{
			  return if(($elements[1]->elements())[0]->literal() == 0); #If this number is 1 (TRUE) rule is true
			  return $self->violation($DESC, $EXPL, $element) if(($elements[1]->elements())[0]->literal() == 1); #If the number is 0 (FALSE) rule is false.
			}
		  }
		}
		
		if ($conditionWord eq 'while')
		{
			for(my $i = 1; $i < $#elements; $i++) # Looking at the elements inside.
			{
			  return if !($elements[$i]->isa('PPI::Token::Whitespace')); #If there is anything else than whitespaces this rule is passed
			}
			return $self->violation($DESC, $EXPL, $element); #Otherwise 'while()' is always true.
		}
	}
	elsif( $elem->isa('PPI::Structure::For') ) #In a case of a C-type for 
	{	
		for(my $i = 1; $i < $#elements - 1; $i++) #Looking at the elements inside.
		{
		  return if( !($elements[$i]->isa('PPI::Token::Whitespace')) && ($elements[$i] ne ';')); #If there is anything than whitespaces and semicolons the rule is passed.
		}
		return $self->violation($DESC, $EXPL, $element); #Otherwise 'for(;;)' is always true.
	}

	return;
}

1;