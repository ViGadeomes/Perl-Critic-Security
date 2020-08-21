package Perl::Critic::Policy::Variables::ProhibitAssignementWithoutUse;

use 5.006001;
use strict;
use warnings;
no warnings 'recursion';
use List::MoreUtils qw(first_index);

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.138';


#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => "No use of a variable making it a dead store";
Readonly::Scalar my $EXPL => " needs to be used even before re-assignement.";

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity 	 { return $SEVERITY_HIGH	  }
sub default_themes		 { return qw{core security}   } 
sub applies_to			 { return 'PPI::Statement::Variable' }

#-----------------------------------------------------------------------------

sub violates {
  my ($self, $elem, undef) = @_;

  return if $elem->type() eq 'our'; #We delete cases were it is a our because its assignement can go outside the file...

  my @violations;

  my $parent = $elem->parent();
  my @parent_elements = $parent->elements();
  my $index = first_index { $_ == $elem } @parent_elements;

  my @variables = $elem->symbols(); #We catch all the variables defined on this line.

  for(@variables) #for each...
  {
    my @results = ($_);

    my $delete = pop(@results) unless( ($elem->first_token()->snext_sibling()->snext_sibling() eq "=") && (($_->parent()->isa('PPI::Structure::List')) || ($_->parent() == $elem)) ); #false positive when there is no assignement.

    my @res = parentVar($_, $parent, $index, @results); #Search for all assignements during the variable's life.
    pop @res; #Delete the last element which is the $var to have its name.

    push(@violations, @res); #Push the result into the violations table
  }

  return if @violations < 1;
  if(@violations > 0)
  {
    my $explanation;
    for(my $i = 0; $i <= $#violations; $i++) #We create ONE violation message for all violations returned.
    {
      my $var = $violations[$i]->symbol();
      if($i==0)
      {
        $explanation = "$var" . $EXPL;
        next;
      }
      else
      {
        my $file = $violations[$i]->logical_filename();
        my $line = $violations[$i]->line_number();
        my $colu = $violations[$i]->column_number();
        $explanation = $explanation . "  (Severity: 4)\n$file: $DESC at line $line, column $colu. $var" . $EXPL;
      }
    }
    return $self->violation($DESC, $explanation, $violations[0]);
  }
  return;
}

#####
#This recursive function handles the cases where we need to find the parent of our current element.
#
#@params =
#* $var : element which represents the last re-assignement of the variable.
#* $element : element which represents the last re-assignement of the variable.
#* $index : index of the element we were at previously.
#* @results : elements which represent assignement and re-assignement of variables not used.
#
#@returns =
#* @results : elements which represent assignements and re-assignements of variables not used or currently undetermined.
#####
sub parentVar
{
  my $var = shift @_;
  my $element = shift @_;
  my $index  = shift @_;
  my @results = @_;

  @results = useVar($var, $element, $index, @results); #We start to look at next element not already done in the children of it
  $var = pop @results;

  my $parent = $element->parent();

  return @results, $var if(!defined($parent));

  return (), $var if($parent->isa('PPI::Structure::List')); #Avoid a false positive : "open(my $file, '<<', '/etc/test.txt');"

  unless( $element->isa('PPI::Statement::Compound') || $element->isa('PPI::Statement::For') || $element->isa('PPI::Statement::Sub') || $element->isa('PPI::Statement::Scheduled') ) #Cases where to not go for the parent.
  {
    my @parent_elements = $parent->elements();

  	$index = first_index { $_ == $element } @parent_elements;

  	@results = parentVar($var, $parent, $index, @results);
    $var = pop @results;
  }
  return @results, $var;
}

#####
#This recusrive function handles the cases where we need to look at the children of our current element.
#
#@params =
#* $var : element which represents the last re-assignement of the variable.
#* $element : element which represents the last re-assignement of the variable.
#* $index : index of the element we were at previously.
#* @results : elements which represent assignement and re-assignement of variables not used.
#
#@returns =
#* @results : elements which represent assignement and re-assignement of variables not used.
#####
sub useVar
{
  my $var = shift @_;
  my $element = shift @_;
  my $index = shift @_;
  my @results = @_;

  return @results, $var if($element->isa('PPI::Token')); #we return if it's a token.

  my @elements = $element->elements();
  my $delete;

  $index += 1 unless !$index;

  my $alterVar = $var;
  $alterVar =~ s/%|@/\$/;

  FOR : for(my $i = $index; $i <= $#elements; $i++)
  {
    if( ($elements[$i]->isa('PPI::Token::Symbol')) && ($elements[$i]->symbol() eq $var->symbol()) ) #If an element is a variable that we are looking for at the moment.
	{
      if( ($element->isa('PPI::Statement')) && ($element->first_token() == $elements[$i]) && ($elements[$i]->snext_sibling() eq '=') && ($element->last_token() eq ';') )#If a re assignement.
	  {
        my $reuse = 0;
		my $next = $elements[$i]->snext_sibling();

        while($next ne $element->last_token())
		{
		  $next = $next->snext_sibling();

          if($next->isa('PPI::Token::Symbol'))
          {
            $reuse = 1 if $next->symbol() eq $var->symbol();
          }
          elsif( $next->isa('PPI::Structure::List') ) #We look at the cases where there is more than one re-assignement, and verify that the re-assignement use the old assignement.
          {
            my @array = $next->children();
            for(@array)
            {
              $reuse = 1 if( ($_ =~ /\Q$var/) || ($_ =~ /\Q$alterVar/) );
            }
          }
          elsif($next->isa('PPI::Structure::Subscript')) #Case where the variable is used in a calcul for the index
          {
            my $expression = ($next->children())[0];
            $reuse = 1 if( ($expression =~ /\Q$var/) || ($expression =~ /\Q$alterVar/) );
          }
          elsif($next->isa('PPI::Token::Quote::Interpolate') || $next->isa('PPI::Token::Quote::Double') || $next->isa('PPI::Token::QuoteLike::Readline')) #Case where the variable is used in a string or a user input.
      	  {
            my $string;
            $string = $next->string() unless $next->isa('PPI::Token::QuoteLike::Readline');
            $string = $next if $next->isa('PPI::Token::QuoteLike::Readline');
      
      		$reuse = 1 if( ($string =~ /\Q$var/) || ($string =~ /\Q$alterVar/) );
       	  }
	    }
        $delete = pop @results if($reuse || ($var ne $elements[$i]->symbol()) ); #We delete the current variable from the list if it is used in the same line as it's reassignement.
        $var = $elements[$i]; #We change the current value.
        push(@results, $var); #We push it in the array (only deleted when used before end of area of assignement or re-assignement).
	  }
      else
	  {
        $delete = pop @results if ($var == $results[$#results]); #Otherwise we delete ONLY ONCE the variable from the list.
      }
	}
	elsif( $elements[$i]->isa('PPI::Structure::List') ) #If in a list we look at it and delete the variable if used and not already deleted. 
    {
      my @array = $elements[$i]->children();
      for(@array)
      {
        $delete = pop @results if( (($_ =~ /\Q$var/) || ($_ =~ /\Q$alterVar/)) && ($var == $results[$#results]) );
      }
    }
    elsif($elements[$i]->isa('PPI::Structure::Subscript')) #Same in a subscript.
    {
      my $expression = ($elements[$i]->children())[0];
      $delete = pop @results if( (($expression =~ /\Q$var/) || ($expression =~ /\Q$alterVar/)) && ($var == $results[$#results]) );
    }
    elsif($elements[$i]->isa('PPI::Token::Quote::Interpolate') || $elements[$i]->isa('PPI::Token::Quote::Double') || $elements[$i]->isa('PPI::Token::QuoteLike::Readline')) #Same in a string/input reader.
	{
      my $string;
      $string = $elements[$i]->string() unless $elements[$i]->isa('PPI::Token::QuoteLike::Readline');
      $string = $elements[$i] if $elements[$i]->isa('PPI::Token::QuoteLike::Readline');

	  $delete = pop @results if( (($string =~ /\Q$var/) || ($string =~ /\Q$alterVar/)) && ($var == $results[$#results]) );
 	}
	elsif( !$elements[$i]->isa('PPI::Token') ) #If non of these where done and the element isn't a token we go one step deeper in this element.
	{
      my $len = @results if( $element->isa('PPI::Statement::Compound') && $elements[$i]->isa('PPI::Structure::Block') && ($element->type() eq 'if') );
      @results = useVar($var, $elements[$i], 0, @results);
      $var = pop @results;
      if( defined($len) ) #Considering a If/unless statement that can't execute more than one block in the case of 'elsif's and 'else's We only look at the first where there is a new re-assignement and skip the rest(could be improved).
      {
        last FOR if @results > $len;
      }
    }
  }
  return @results, $var;
}

1;

#-----------------------------------------------------------------------------