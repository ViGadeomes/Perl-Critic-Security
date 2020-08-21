package Perl::Critic::Policy::ControlStructures::ProhibitMissingDefaultInGiven;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.138';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Missing default block in given};
Readonly::Scalar my $EXPL => q{A given statement always needs to have a default block};

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity 	 { return $SEVERITY_HIGH }
sub default_themes		 { return qw/core security/ } 
sub applies_to			 { return 'PPI::Statement' }

#-----------------------------------------------------------------------------

sub violates {
  my ($self, $elem, undef) = @_;

  #We look at given statements.
  return if !($elem->isa('PPI::Statement::Given'));

  my @given = $elem->elements();

  my $element = $elem->first_token();

  #We look at elements in the given statement.
  for(@given)
  {
    #We enter the code block of the given
	if($_->isa('PPI::Structure::Block'))
    {
      my @block = $_->elements();

      return if $_->braces() ne '{}';

	  #We look at 'When' blocks
      for(@block)
      {
        if($_->isa('PPI::Statement::When'))
        {
          #If it's a default block there's no error.
		  return if $_->first_token() eq 'default';
        }
      }
    }
  }
  #If we arrive there, there is an error.
  return $self->violation($DESC, $EXPL , $element);
}

1;
#-----------------------------------------------------------------------------