package Perl::Critic::Policy::ControlStructures::ProhibitMissingElseInIfElsif;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.138';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => "Missing else block with if/elsif";
Readonly::Scalar my $EXPL => "An IF/ELSIF statement always needs to have a else block.";

#-----------------------------------------------------------------------------

sub supported_parameters { return () }
sub default_severity 	 { return $SEVERITY_HIGH }
sub default_themes		 { return qw/core security/ }
sub applies_to			 { return 'PPI::Statement' }

#-----------------------------------------------------------------------------

sub violates {
  my ($self, $elem, undef) = @_;

  #We only look at 'if' and 'unless' statements
  return if !($elem->isa('PPI::Statement::Compound'));
  
  my $element = $elem->first_token();
  return if $elem->first_token() !~ /if|unless/;

  #elements of the statement
  my @if = $elem->elements();

  #We suppose at first that no elsif and else blocks are presents.
  my $elsif = 0;
  my $else = 0;

  #We look at elements of the statement.
  for(@if)
  {
	#If one of them is present, we set the corresponding value to TRUE
	$elsif = 1 if $_ eq 'elsif';
    $else = 1 if $_ eq 'else';
  }
  #We return false only in the case where there is a /if|unless/ -> (elsif ->){1..*} . So without else after elsifs 
  return $self->violation($DESC, $EXPL , $element) if($elsif && !$else);
  return;
}

1;
#-----------------------------------------------------------------------------