package Perl::Critic::Policy::InputOutput::ProhibitImproperInputValidation;

use 5.006001;
use strict;
use warnings;
use List::MoreUtils qw(first_index);

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.138';


#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => "No verification of user's input before using it";
Readonly::Scalar my $EXPL => "A verification of user's inputs is necessary to prevent unexpected results due to bad inputs.";

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity 	 { return $SEVERITY_HIGH	  }
sub default_themes		 { return qw{core security}   } 
sub applies_to			 { return 'PPI::Token' }

#-----------------------------------------------------------------------------

#####
#This recursive function makes the test on the children of the current element.
#
#@params = 
#* $var = element which represents the variable that we are looking at.
#* $element = element where we currently are at.
#* $index = index of the child we stopped previously.
#
#@returns =
#* $verified : boolean is 1 when verified; undef if not determined; 0 if used before verification.
#
#####
sub nextElement
{
  my ($var, $element, $index) = @_;
 
  return if !(defined($element));

  $index += 1 if defined($index); #If we already looked at some elements, we then need to look at other elements.
  $index = 0 if !defined($index); #There we need to look at everything.

  my $verified;

  my @elements = $element->elements();

  for(my $i = $index; $i <= $#elements; $i++)
  {
	if($elements[$i]->isa('PPI::Statement')) #We see if there is a use of it here.
	{
	  $verified = variableUse($var, $elements[$i]);
  
      return $verified if defined($verified);
	}
	if($elements[$i]->isa('PPI::Structure::Condition')) #We see if there is a verification of it here.
	{
	  $verified = variableCondition($var, $elements[$i]);

	  return $verified if defined($verified);
	}
	elsif( !($elements[$i]->isa('PPI::Token')) ) #Otherwise we go deeper in th element.
	{
	  $verified = nextElement($var, $elements[$i]);

	  return $verified if defined($verified);
	}
  }
  return $verified;
}

#####
#This recursive function makes the test on an assignement.
#
#@params = 
#* $var = element which represents the variable that we are looking at.
#* $element = element where we currently are at.
#* $index = index of the child we stopped previously.
#
#@returns =
#* $verified : boolean is 1 when verified; undef if not determined; 0 if used before verification.
#
#####
sub variableUse
{
  my ($var, $element) = @_;

  return 1 if( ($element->first_token() eq $var) && ($element->first_token()->snext_sibling() eq '=~') && ($element->first_token()->snext_sibling()->snext_sibling()->isa('PPI::Token::Regexp::Substitute')) ); # If it's a substitution on the variable we return that it is good.

  my $verified;
  my $condition = 0;
  my $chomp;
  $chomp = 1 if $element->first_token() eq $var; #assignement after declaration
  $chomp = 0 if $element->first_token() ne $var; #assignement during declaration
  
  my @elements = $element->elements();
  for(my $i = 0; $i <= $#elements; $i++)
  {
    if($elements[$i] =~ /chomp|chop/) #If assignement on the same line that the chomp/chop.
    {
      $chomp = 1;
    }
    if($elements[$i]->isa('PPI::Structure::List')) # If this is a list, we look if the variable is used.
    {
      for(($elements[$i])->children())
      {
        if($_ =~ /\Q$var/)
        {
          $verified = 0 if $chomp == 0;
          return if $chomp == 1;
        }
      }
    }
    if($elements[$i] eq '?') #In this case the expression before is a condition so we look if the variable was in and we now if it has been verified or not.
    {
      $verified = 1 if defined($verified) && !$verified;
    }
    if($elements[$i] eq $var) #If the variable is found...
	{
	  $verified = 0 if $chomp == 0;
      return if $chomp == 1;
	}
	if( ($elements[$i] =~ /if|unless|until|while/) && !$verified) #If there is a condition at the end of the statement.
	{
	  $condition = 1;
	}
	if($condition) #If there is a condition we look if the variable is in or not.
	{
	  $verified = 1 if $elements[$i] eq $var;
	}
  }
  return $verified;
}

#####
# This function looks at the test of the variable in a condition.
#
#@params = 
#* $var = element which represents the variable that we are looking at.
#* $element = element where we currently are at.
#
#@returns =
#* $verified : boolean is 1 when verified; undef if not determined.
#
#####
sub variableCondition
{
  my ($var, $element) = @_;

  return if !defined($element);

  my @elements = $element->elements();

  my $verified;

  for(@elements) # We verify if the variable is part of a test and so we return true.
  {
    if($_ eq $var) 
	{
      return 1;
	}
    if($_->isa('PPI::Structure::List'))
    {
      for my $child($_->children())
      {
        return 1 if $child =~ /\Q$var/;
      }
    }
    if($_->isa('PPI::Token::Quote::Double') || $_->isa('PPI::Token::Quote::Interpolate'))
    {
      my $string = $_->string();
		  
	  return 1 if $string =~ /\Q$var/;
    }
	elsif( !($_->isa('PPI::Token')) )
	{
	  $verified = variableCondition($var, $_);
	  return $verified if $verified;
	}
  }
  return $verified;
}

#####
# This recursive function takes care of calling the functions to his children and his father unless he is the last parent for the assignement of this variable.
#
#@params = 
#* $var = element which represents the variable that we are looking at.
#* $element = element where we currently are at.
#* $index = index of the child which has been already verified.
#* $father = last parent where the variable is defined.
#
#@returns =
#* $result : boolean is 1 when verified; undef if not determined.
#
#####
sub parentVar
{
  my ($var, $element, $index, $father) = @_;

  my $result = nextElement($var, $element, $index); # Verification on the children not already done.

  return $result if defined($result); # If we already have the answer.

  my $parent = $element->parent(); # We prepare the parent.

  return $result if(!defined($parent)); # If it is the PPI::Document (on top of the PDOM tree).

  unless($element eq $father)
  {
    my @parent_elements = $parent->elements();

  	$index = first_index { $_ == $element } @parent_elements;

  	$result = parentVar($var, $parent, $index, $father); # We verify our father.
  }
  return $result;
}

#####
# This recursive function searches and return the father element in which the variable is defined.
#
#@params = 
#* $var = element which represents the variable that we are looking at.
#* $element = element where we currently are at.
#* $index = index of the child which has been already verified.
#
#@returns =
#* $element : Big father where the variable is defined.
#
#####
sub superiorVar
{
  my ($var, $element, $index) = @_;

  return $element if( ($element->isa('PPI::Document')) || ($element->isa('PPI::Structure::Block') && $element->parent()->isa('PPI::Document')) ); #If this is a PPI::Document or a block alone we return our element.

  my @elements = $element->elements();

  $index -= 1;

  for(my $i = $index; $i >= 0; $i--) 
  {
    if($elements[$i]->isa('PPI::Statement::Variable')) #We search where the variable is defined and when we find it, we return its parent.
    {
      my @symbols = $elements[$i]->symbols();
      for(@symbols)
      {
        return $element if $_ eq $var;
      }
    }
  }
  my $parent = $element->parent();

  my @parent_elements = $parent->elements(); 

  $index = first_index { $_ == $element } @parent_elements;

  return superiorVar($var, $parent, $index); #If we didn't find it we look further.
}

#-----------------------------------------------------------------------------

sub violates {
  my ($self, $elem, undef) = @_;

  return if ($elem ne '<>' && $elem ne '<STDIN>' && $elem ne '<ARGV>'); #If this is not a diamon operator.

  return if ($elem->parent()->isa('PPI::Statement')) && ($elem->parent()->first_token() eq $elem) && ($elem->snext_sibling() eq ';'); # false positive : "<>;"
  
  my $var;

  if($elem->sprevious_sibling() eq '=') # If a name is given;
  {
	$var = $elem->sprevious_sibling()->sprevious_sibling();
  }
  else # Otherwise, it is the default variable.
  {
	$var = '$_';
  }

  my $parent = $elem->parent();
  my @parent_elements = $parent->elements();

  my $index = first_index { $_ == $elem } @parent_elements;

  my $father = superiorVar($var, $parent, $index); #We search the father.
  my $result = parentVar($var, $parent, $index, $father); #We look if the variable has been verified before 
  return $self->violation( $DESC, $EXPL, $elem ) if !$result;
  return;
}

1;

#-----------------------------------------------------------------------------