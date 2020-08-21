package Perl::Critic::Policy::ControlStructures::ProhibitEmptyCodeBlock;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.138';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Code block is empty};
Readonly::Scalar my $EXPL => q{All code blocks have to not be empty};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity 	 { return $SEVERITY_HIGH	  }
sub default_themes		 { return qw{core security}   } 
sub applies_to			 { return 'PPI::Structure'  }

#-----------------------------------------------------------------------------

sub violates {
  my ($self, $elem, undef) = @_;

  #We only look at code blocks.
  return if !($elem->isa('PPI::Structure::Block'));
  
  #with brackets
  return if $elem->braces() ne '{}';
  
  my @elements = $elem->children();
  #We look at all the block appart from first and last brackets.
  for(@elements)
  {
    #we return no error if there's something in the block appart from whitespaces
	return if !($_->isa('PPI::Token::Whitespace'));
  }
  #If we arrive there then there is an error.
  return $self->violation( $DESC, $EXPL, $elem->first_element());
}

1;
#-----------------------------------------------------------------------------