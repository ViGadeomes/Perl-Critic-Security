package Perl::Critic::Policy::ControlStructures::ProhibitInfiniteLoop;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.138';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Infinite loop};
Readonly::Scalar my $EXPL => q{This loop will execute indefinitely};

Readonly::Scalar my $SCOLON => q{;};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity 	 { return $SEVERITY_HIGH	  }
sub default_themes		 { return qw{core security}   } 
sub applies_to			 { return 'PPI::Structure'  }

#-----------------------------------------------------------------------------

sub violates {
	my ($self, $elem, undef) = @_; 
	
	return if !( ($elem->isa('PPI::Structure::For')) || ($elem->isa('PPI::Structure::Condition')) ) ; # We delete cases we don't care
	
	my $element = $elem->first_element(); 
	
	my @elements = $elem->elements(); # begins with '(' and ends with ')'
  
	my $conditionWord = $elem->parent()->first_token();
	return if($conditionWord !~ /while|until/); # We are only looking to loops.
	
	if($elem->isa('PPI::Structure::Condition'))
	{
		if($conditionWord eq 'while')
		{
			if( (@elements == 3))
			{
				if($elements[1]->isa('PPI::Statement::Expression'))
				{
					if( ($elements[1]->elements() == 1) && (($elements[1]->elements())[0]->isa('PPI::Token::Number')) )
					{
						return $self->violation($DESC, $EXPL, $element) if (($elements[1]->elements())[0]->literal() == 1); # We see if it is 'while(1)'.
					}
				}
			}

			for(my $i = 1; $i < $#elements; $i++)
			{
				return if !($elements[$i]->isa('PPI::Token::Whitespace'));
			}
			return $self->violation($DESC, $EXPL, $element); # We see if it is 'while()'.
		}
		elsif($conditionWord eq 'until')
		{
			if( (@elements == 3))
			{
				if($elements[1]->isa('PPI::Statement::Expression'))
				{
					if( ($elements[1]->elements() == 1) && (($elements[1]->elements())[0]->isa('PPI::Token::Number')) )
					{
						return $self->violation($DESC, $EXPL, $element) if (($elements[1]->elements())[0]->literal() == 0); # We see it is is 'until(0)'.
					}
				}
			}
		}
		
	}
	elsif( $elem->isa('PPI::Structure::For') )
	{
		for(my $i = 1; $i < $#elements - 1; $i++)
		{
			return if( !($elements[$i]->isa('PPI::Token::Whitespace')) && ($elements[$i] ne ';')); 
		}
		return $self->violation($DESC, $EXPL, $element); # We see if it is 'for(;;)'.
	}
	return;
}

1;
#-----------------------------------------------------------------------------