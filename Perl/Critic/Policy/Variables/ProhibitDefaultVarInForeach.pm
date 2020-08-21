package Perl::Critic::Policy::Variables::ProhibitDefaultVarInForeach;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.138';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => "Use of a default variable in a foreach loop";
Readonly::Scalar my $EXPL => "It is better to name the variable of the foreach loop.";

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity 	 { return $SEVERITY_HIGH }
sub default_themes		 { return qw/core security/ } 
sub applies_to			 { return 'PPI::Statement' }

#-----------------------------------------------------------------------------

sub violates {
  my ($self, $elem, undef) = @_;

  #We only want for(@array) statements
  return if !($elem->isa('PPI::Statement::Compound'));
  return if $elem->type() ne 'foreach';

  
  my $element = $elem->first_token();
  
  my @foreach = $elem->elements();
  
  #We start from the beginning
  for(@foreach)
  {
	  #we stop the loop when we encounter the condition block of the foreach.
	  last if $_->isa('PPI::Structure::List');
	  #If there is a variable put before the condition block then it's not an error and we return nothing.
	  return if $_->isa('PPI::Token::Symbol');
  }
  #If we arrive here, it is then an error.
  return $self->violation($DESC, $EXPL , $element);
}

1;
#-----------------------------------------------------------------------------