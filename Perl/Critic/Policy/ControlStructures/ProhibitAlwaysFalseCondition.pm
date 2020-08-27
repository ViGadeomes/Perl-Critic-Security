package Perl::Critic::Policy::ControlStructures::ProhibitAlwaysFalseCondition;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.138';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Always False Condition};
Readonly::Scalar my $EXPL => q{This condition is always false};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity 	 { return $SEVERITY_HIGH	  }
sub default_themes		 { return qw{core security}   } 
sub applies_to			 { return 'PPI::Structure'  }

#-----------------------------------------------------------------------------

sub violates 
{
	my ($self, $elem, undef) = @_;
 
	return if !($elem->isa('PPI::Structure::Condition')); #We delete cases that we don't care
	
	my $element = $elem->first_element();
	
	my @elements = $elem->elements(); #begins with '(' and ends with ')'
	
	my $conditionWord = $elem->parent()->first_token(); #We take the first element to see the type of condition structure
  
	if( (@elements == 3)) #3 elements
	{
		if($elements[1]->isa('PPI::Statement::Expression')) #first element is '(' last is ')' and in the middle it is always an expresison
		{
			if( ($elements[1]->elements() == 1) && (($elements[1]->elements())[0]->isa('PPI::Token::Number')) ) #if only one element which is a number
			{
				return if(($elements[1]->elements())[0]->literal() == 1); #If this number is 1 (TRUE) rule is false
				return $self->violation($DESC, $EXPL, $element) if(($elements[1]->elements())[0]->literal() == 0); #If the number is 0 (FALSE) rule is true.
			}
		}
	}
	return;
}

1;