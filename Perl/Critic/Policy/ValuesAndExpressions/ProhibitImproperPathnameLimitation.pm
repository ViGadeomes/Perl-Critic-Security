package Perl::Critic::Policy::ValuesAndExpressions::ProhibitImproperPathnameLimitation;

use 5.006001;
use strict;
use warnings;
no warnings 'recursion';
use List::MoreUtils qw(first_index);

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.138';


#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => "Improper limitation of a Pathname.";
Readonly::Scalar my $EXPL => "No verification of the pathname from an untrusted source (user or external subroutine) can lead to a Path traversal.";

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity 	 { return $SEVERITY_HIGH	  }
sub default_themes		 { return qw{core security}   } 
sub applies_to			 { return 'PPI::Token::Word'  }

#-----------------------------------------------------------------------------

#####
#This recusrive function handle the cases where we need to find the parent of our current element.
#
#@params =
#* $var : element which represents the last re-assignement of the variable.
#* $element : element which represents the last re-assignement of the variable.
#* $index : index of the element we were at previously.
#
#@returns =
#* $result : result 1 if the pathname has been verified; undef if not determined; 0 if used before verification.
#####
sub parentVar
{
  my ($var, $element, $index) = @_;
  
  my $result = varDef($var, $element, $index); #We look at the children of the element.
  
  return $result if defined($result);
  
  my $parent = $element->parent();
  
  return if !defined($parent);
  
  unless($element->isa('PPI::Statement::Sub')) #We then see its parents when necessary
  {
    my @parent_elements = $parent->elements();
  
  	$index = first_index { $_ == $element } @parent_elements;
  
  	$result = parentVar($var, $parent, $index);
  }
  
  return $result;
}

#####
#This function handles the case where we need to look at the children of the current element.
#
#@params =
#* $var : element which represents the last re-assignement of the variable.
#* $element : element which represents the last re-assignement of the variable.
#* $index : index of the element we were at previously.
#
#@returns =
#* $result : result 1 if the pathname has been verified; undef if not determined; 0 if used before verification.
#####
sub varDef
{
  my ($var, $element, $index) = @_;
  my $value;
  my @elements = $element->elements();
  $index -= 1 if defined($index);
  $index = $#elements if !defined($index);
  
  if($index > 0)
  {
    for(my $i = $index; $i >= 0; $i--)
    {
      if($elements[$i]->isa('PPI::Structure::Compound')) #Call another function more specialized for this case.
      {
        my $value = variableCondition($var, $elements[$i]);
        
        return $value if defined($value);
      }
      if($elements[$i]->isa('PPI::Statement') && $elements[$i]->first_token() eq $var && $elements[$i]->first_token()->snext_sibling() eq '=~' && $elements[$i]->last_token() eq ';') #To see if a modification is made to the variable.
      {
        my $element = $elements[$i]->first_token();
        my $next = $element->snext_sibling();
        
        while($next ne ';' && !$next->isa('PPI::Token::Regexp::Substitute'))
        {  
          $next = $next->snext_sibling();
        }
        next if $next eq ';';
  
        my $match = $next->get_match_string();
        my $substitute = $next->get_match_string();
        
        next if $match !~ m=\\\.\\\.\\\/=;
        
        return 1 if $substitute =~ m//;
      }
      elsif($elements[$i]->isa('PPI::Statement::Variable')) #In a case of a variable definition we go in the variableDefinition function
      {
        $value = variableDefinition($var, $elements[$i]);
        
        return $value if defined($value);
      }
      elsif( !($elements[$i]->isa('PPI::Token')) ) #If nothing was possible and the element isn't a token, we go deeper in the element.
      {
        $value = varDef($var, $elements[$i]);
        
        return $value if defined($value);
      }
    }
  }
  return $value;
}

#####
#This recursive function handles the case where we need to look at a condition to see if there is the variable.
#
#@params =
#* $var : element which represents the last re-assignement of the variable.
#* $element : element which represents the last re-assignement of the variable.
#
#@returns =
#* $result : result 1 if the pathname has been verified; undef if not determined; 0 if used before verification.
#####
sub variableCondition
{
  my ($var, $element) = @_;
  
  my @elements = $element->elements();
  
  for(@elements)
  {
    return 0 if ( ($_->isa('PPI::Token::Symbol')) && ($_ eq $var) );
    if( $_->isa('PPI::Statement') && ($_->first_token() eq $var) ) #In a case of test on the variable in a condition...
    {
      my $element = $_->first_token();
      my $next = $element->snext_sibling();

      while($next ne ';' && !$next->isa('PPI::Token::Regexp::Substitute')) #We search the regexp.
      {
        $next = $next->snext_sibling();
      }
      next if $next eq ';'; #If there is none we go to the next.

      my $match = $next->get_match_string();
      my $substitute = $next->get_match_string();

      next if $match !~ m=\\\.\\\.\/\\\/=;
      return 1 if $substitute =~ m//; #Verify if the verification is well done.
    }
    elsif(!$_->isa('PPI::Token')) #Going deeper to look at it.
    {
      my $result = variableCondition($var, $_);
      return $result if defined($result);
    }
  }
  return;
}

#####
#This function handles the case where we need to look at a variable definition to see if there is the variable.
#
#@params =
#* $var : element which represents the use variable.
#* $element : element where we are at.
#
#@returns =
#* $result : result 1 if the pathname has been verified; undef if not determined; 0 if used before verification.
#####
sub variableDefinition
{
  my ($var, $element) = @_;
  my @symbols = $element->symbols();
  my $index;
  for(my $i = 0; $i <= $#symbols; $i++) #We verify if the variable is assigned there and if so we count its number.
  {
    if($var eq $symbols[$i])
    {
      $index = $i;
      last;
    }
  }
  
  return if !(defined($index)); #If there isn't the variable we return
  my @variable = $element->elements();
  
  if(@symbols == 1) 
  {
    my $values = 0;
    for(my $i = 0; $i <= $#variable; $i++) # We look at the assignement statement and see if the assignement is a function or a user input and so we return 0 otherwise 1.
    {
      if($variable[$i] eq  '=')
      {
        $values = 1;
      }
      elsif( !($variable[$i]->isa('PPI::Token::Whitespace')) && $values )
      {
        return 0 if $variable[$i] =~ /<>|<ARGV>|<STDIN>/;
        
        return 0 if($variable[$i]->isa('PPI::Token::Word') && $variable[$i+1]->isa('PPI::Structure::List'));
        return 1;
      }
    }
  }
  else
  {
    my $z;
    my $values = 0;
    LAST: for($z = 0; $z <= $#variable; $z++) #Same thing considering that we have more than one assignement.
    {
      if($variable[$z] eq  '=')
      {
        $values = 1;
      }
      if( !($variable[$z]->isa('PPI::Token::Whitespace')) && !($variable[$z] =~ /\(|\)/ ) )
      {
        if($variable[$z] eq ',')
        {
          $index--;
        }
        if($index == 0)
        {
          return 0 if $variable[$z] =~ /<>|<ARGV>|<STDIN>/;
          return 0 if($variable[$z]->isa('PPI::Token::Word') && $variable[$z]->snext_sibling()->isa('PPI::Structure::List'));
          return 1;
        }
      }
    }
  }
  return;
}

#main
sub violates {
  my ($self, $elem, undef) = @_;

  return if $elem ne 'open'; #We only look at the 'open' function

  my $parent = $elem->parent();
 
  my @elements_parent = $parent->elements();
  
  my $index = first_index { $_ == $elem } @elements_parent;
	
  $index += 1;
	
  my $parameters;
	
  while($elements_parent[$index]->isa('PPI::Token::Whitespace'))
  {
	$index += 1;
  }

  my @elements;
  my $commas = 0;
  if($elements_parent[$index]->isa('PPI::StructureList')) #Taking parameters from the list or without depending the case.
  {
    $parameters = (($elements_parent[$index])->children())[0];
	
	@elements = $parameters->elements();
  }
  else
  {
    for(my $i = $index; $i < $#elements_parent; $i++)
    {
      push(@elements, $elements_parent[$i]);
    }
  }

  for(@elements) #Counting the number of commas.
  {
    $commas += 1 if $_ eq ',';
  }
  my $second = 0;
	for(@elements) #We look at the parameter that opens the file and save the variable if there is one and then verify its verification.
	{
      if($_ eq ',')
	  {
	 	$second += 1;
	  }
	  if($second == $commas && $_->isa('PPI::Token::Symbol'))
	  {
        my $var = $_;
        my $input = parentVar($var, $parent);
      
        return $self->violation($DESC, $EXPL, $var) unless $input;
	  }
	}
	return;
}

1;

#-----------------------------------------------------------------------------