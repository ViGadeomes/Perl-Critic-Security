package Perl::Critic::Policy::RegularExpressions::RequireUseOfSavedRegularExpression;

use 5.006001;
use strict;
use warnings;
no warnings 'recursion';
use List::MoreUtils qw(first_index);

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.138';


#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => "No use or save of regexp results";

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity 	 { return $SEVERITY_HIGH	  }
sub default_themes		 { return qw{core security}   } 
sub applies_to			 { return 'PPI::Token::Regexp' }

#-----------------------------------------------------------------------------

sub violates {
  my ($self, $elem, undef) = @_;
	
  #catch the strings of the regexp and find the parenthesis
  my $match = $elem->get_match_string();
	my $substitute = $elem->get_substitute_string();
  my @variables = ($match =~ m/[^\\]\(/g );
  
  return if @variables == 0;
  
  #change them to corresponding variables
  my $number = 1;
  for(@variables)
  {
    $_ = "\$" . $number;
    $number++;
  }
  
  
  
  #Find the variables used in the regexp
  my @backslashVar = ( $match =~m/[^\\]\\[1-9]/g );
  
  #Deleting the ones used
  for my $used (@backslashVar)
  {
    $used =~ s/\\/\$/;
    for(my $i = 0; $i <= $#variables; $i++)
    {
      if($used eq $variables[$i])
      {
        splice(@variables, $i, 1);
        last;
      }
    }
  }
  return if @variables == 0;
  
  #Find the variables used in the substitute part if exists
  if(defined($substitute))
  {
    my @substituteVar = ($substitute =~ m/[^\\](\$\{?[1-9]\}?)/g);
    push(@substituteVar, ($substitute =~ m/^(\$\{?[1-9]\}?)/g) );
    
    #Deleting the ones used
    for my $used (@substituteVar)
    {
      $used =~ s/\{|\}//g;
      for(my $i = 0; $i <= $#variables; $i++)
      {
        if($used eq $variables[$i])
        {
          splice(@variables, $i, 1);
          last;
        }
      }
    }
  }
  
  return if @variables == 0;
  
  #Looking outside the regexp if the rest is used before another regexp
  my $EXPL = "Magic variable";
  my $problem = 0;
  for(my $i = 0; $i <= $#variables; $i++)
	{
    my $parent = $elem->parent();
    my $index = first_index { $_ == $elem } $parent->elements();
    my $result = parentVar($variables[$i], $parent, $index);
    unless($result)
    {
      $problem = 1;
      $EXPL .= " $variables[$i],";
    }
	}
  $EXPL =~ s/(\$[1-9]), (\$[1-9]),$/$1 and $2/;
  $EXPL =~ s/(\$[1-9]),$/$1/;
  $EXPL .= " saved variables haven\'t been used after their save." if $EXPL =~ /and/;
  $EXPL .= " saved variable hasn\'t been used after its save." if $EXPL !~ /and/;
  return $self->violation( $DESC, $EXPL, $elem ) if $problem;
  return;
}

#####
#This recusrive function handle the cases where we need to find the parent of our current element.
#
#@params =
#* $var : element which represents the last re-assignement of the variable.
#* $element : element where we are at in our process to look at the PDOM tree.
#* $index : index of the element we were at previously.
#* $stop : boolean that tells this is the last call of the function and have to return its result no matter it.
#
#@returns =
#* $result : 1 si une utilisation a été faite de la variable avant sa disparition; undef si ce n'est pas déterminé; 0 sinon
#####
sub parentVar
{
  my ($var, $element, $index, $stop) = @_;
  $stop = 0 if !defined($stop); #This variable is necessary to call a last time this function because a regexp variable is defined in the parent when in a condition of a block.
  
  if($element->isa('PPI::Statement::Break')) #false positive : "return $x =~ REGEXP;"
  {
    return 1 if $element->first_token() eq 'return';
  }
  if($element->isa('PPI::Statement::Variable')) #In the case of (..)s from a regexp directly assigned to variables.
  {
    my @symbols = $element->symbols();
    for(my $i = 0; $i <= $#symbols; $i++)
    {
      return 1 if defined($symbols[($var =~ /[1-9]/) - 1]);
    }
  }
  
  if($element->isa('PPI::Statement') && $element->first_element()->snext_sibling() eq '=') #Same but in the case of a re-assignement.
  {
    my $token = $element->first_element();
    
    if($token->isa('PPI::Token::Symbol'))
    {
      return 1 if($var =~ /1/);
    }
    elsif($token->isa('PPI::Structure::List'))
    {
      my $colons = ($var =~ /[1-9]/) - 1;
      my $expression = ($token->children())[0];
      return 1 if($expression =~ /(( |)*)\$\w(\1,\1\$\w){$colons}/);
    }
  }
  
  my $result;

  $result = useVar($var, $element, $index) unless(defined($element->parent()) && $element->parent()->isa('PPI::Structure::Condition'));
  #We look at the code after our current element in this parent which accelerate the time of execution.
  return $result if defined($result);
  return $result if $stop; #if $stop is true then the variable isn't defined anymore.
  
  #Cases when the variables stop to be defined so we don't go further.
  unless($element->isa('PPI::Statement::For') || $element->isa('PPI::Statement::Sub') || $element->isa('PPI::Statement::Scheduled')) 
  {
    my $parent = $element->parent();
  
    return $result if !defined($parent); #protection if there's no parent.

    my @parent_elements = $parent->elements();
  
  	$index = first_index { $_ == $element } @parent_elements; #we find the index of the actual element to do not reverify what have been already verified
  
  	if($element->isa('PPI::Statement::Compound')) #Case of a conditionnal block (with the $stop)
	{
	  $result = parentVar($var, $parent, $index, 1);
	}
	else #otherwise
	{
	  $result = parentVar($var, $parent, $index);
	}
  }
  
  return $result;
}

#####
#This function handles the case where we need to look at the children of the current element.
#@params = 
#* $var : element which represents the last re-assignement of the variable.
#* $element : element where we are at in our process to look at the PDOM tree
#* $index : index of the element we were at previously
#
#@returns : 
#* $result : 1 si une utilisation a été faite de la variable avant sa disparition; undef si ce n'est pas déterminé; 0 sinon
#####
sub useVar
{
  my ($var, $element, $index) = @_;
  
  my $result;

  my @elements = $element->elements();

  $index += 1 if defined($index); #If the index is defined it means that the element at this index is already verified so we can go to the next one.
  $index = 0 if !defined($index); #If the index isn't defined then we can look at all children of the element from the beginning.
  
  for(my $i = $index; $i <= $#elements; $i++)
  {
    if( $elements[$i]->isa('PPI::Structure::List') )
    { #Case of a list, we look if the variable is in and if so then it has been used.
      for($elements[$i]->children())
      {
        return 1 if $_ =~ /\Q$var/;
      }
    }
    elsif($elements[$i]->isa('PPI::Structure::Subscript'))
    { #Case of a subscript, we look if the variable is in and if so then it has been used.
      my $expression = ($elements[$i]->children())[0];
      return 1 if $expression =~ /\Q$var/;
    }
    elsif(!$elements[$i]->isa('PPI::Token'))
    { #In an other case where the element is not a token : 
      $result = useVar($var, $elements[$i]); # We verify the children of this element
  	  return $result unless( !defined($result) || (defined($result) && !$result && $element->isa('PPI::Statement::Compound') && $element->type() eq 'if') ); # We do not return if the element isn't used (can be used later) or when there is a 'if' statement because can be used in 'elsif's and 'else's blocks.
    }
    elsif( ($elements[$i]->isa('PPI::Token::Symbol')) && ($elements[$i] eq $var) ) #If the variable is encountered somewhere we return 1.
	{
      return 1;
	}
    elsif($elements[$i]->isa('PPI::Token::Quote::Interpolate') || $elements[$i]->isa('PPI::Token::Quote::Double')) #If the element is in a list, we return 1.
	{
      my $string = $elements[$i]->string();
	  return 1 if $string =~ /\Q$var/;
	}
    elsif($elements[$i] =~ /=~|!~/ || $elements[$i]->isa('PPI::Token::Regexp')) #If the element is a new regexp, all variables will be lost unless we did something with it which leads to an error.
	{
      return 0;
	}
  }
  return $result;
}

1;

#-----------------------------------------------------------------------------