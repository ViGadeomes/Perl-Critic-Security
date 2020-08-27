package Perl::Critic::Policy::ValuesAndExpressions::ProhibitDivisionByZero;

use 5.006001;
use strict;
use warnings;
use Readonly;
use List::MoreUtils qw(first_index);

use Perl::Critic::Utils qw{ :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.138';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Division by zero};
Readonly::Scalar my $EXPL => q{A division by zero can create unexpected results};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity 	 { return $SEVERITY_HIGH	  }
sub default_themes		 { return qw{core security}   } 
sub applies_to			 { return 'PPI::Token::Operator'  }

#-----------------------------------------------------------------------------
#####
#This recursive function handles the cases where we need to find the parent of our current element and so the previous elements of it.
#
#@params =
#* $var : element which represents the variable that we are looking for.
#* $element : element which represents the current element.
#
#@returns =
#* $value : boolean that says if the rule is respected or not : 0 if not, 1 if good.
#####
sub predecessor
{
  my ($var, $element) = @_;
  return if !(defined($element)); #If the element given is nothing, we return.
  my $value;
  my @elements = $element->elements();
  my $index = first_index { $_ == $element } @elements; #We look at the index where we are at.
  
  if($index >= 0)
  {
    for(my $i = $index; $i >= 0; $i--)
    {
      if($elements[$i]->isa('PPI::Statement::Variable')) # If there is an assignement.
      {
        $value = variableDefinition($var, $elements[$i]); #We look at it.
        return $value if defined($value); #We return the value if defined
      }
    }
  }
  $value = predecessor($var, $element->parent()); # We look at the parent and predecessors of it if necessary.
  return $value; #We return the value
}

#####
#This function looks at the assignement of the variables assigned.
#
#@params =
#* $var : element which represents the variable that we are looking for.
#* $element : element which represents the current element.
#
#@returns =
#* $value : boolean that says if the rule is respected or not : 0 if not, 1 if good.
#####
sub variableDefinition
{
  my ($var, $element) = @_;
  my @symbols = $element->symbols();
  my $index;
  for(my $i = 0; $i <= $#symbols; $i++)
  {
    if($var eq $symbols[$i])
    {
      $index = $i;
      last;
    }
  }
  
  return if !(defined($index));
  
  my @variable = $element->elements();
  
  my $value;
  
  if(@symbols == 1)
  {
    LAST: for(my $i = 0; $i <= $#variable; $i++)
    {
      if($variable[$i] eq  '=')
      {
        for(my $y = $i; $y < $#variable; $y++)
        {
          if( !($variable[$i]->isa('Whitespace')) )
          {
            $value = $variable[$i];
            last LAST;
          }
        }
      }
    }
  }
  else
  {
    my $z;
    LAST: for($z = 0; $z <= $#variable; $z++)
    {
      if($variable[$z] eq  '=')
      {
        for(my $y = $z; $y <= $#variable; $y++)
        {
          if( !($variable[$y]->isa('Whitespace')) && !($variable[$y] =~ /(|)/) )
          {
            if($variable[$y] eq ',')
            {
              $index--;
            }
            if($index == 0)
            {
              $value = $variable[$y];
              last LAST;
            }
          }
        }
      }
    }
  }
  return $value;
}

#-----------------------------------------------------------------------------
sub violates {
  my ($self, $elem, undef) = @_;

  return if $elem ne '/'; #We look at each divisions.
  my $next = $elem->snext_sibling() or return; #we verify the next element. 
  return $self->violation( $DESC, $EXPL, $elem ) if ( ($next->isa('PPI::Token::Number')) && ($next->literal() == 0) ); #If it is a 0, violation.
  
  #Partie plus complète.
  if($next->isa('PPI::Token::Symbol')) #If this is a variable, we look at its last definition.
  {
    my $var = $next;
    return $self->violation( $DESC, $EXPL, $elem ) if !(predecessor($var, $elem->parent()));
  }
  return;
}

1;
#-----------------------------------------------------------------------------