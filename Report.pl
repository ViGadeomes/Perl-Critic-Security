use Perl::Critic;
use Perl::Critic qw{critique};
use strict;
use warnings;
use Path::Iterator::Rule;


print 'PATH: ';
my $path = <>;
chomp $path;

my @violations;


if($path =~ m/(\.pm|\.pl|\.plx)$/)
{
  my $filereport;
  @violations = critique( {-severity => 1}, "$path" );
  
  open ($filereport, '>', "./REPORT.txt") or die "Impossible d'ouvrir le fichier REPORT.txt en écriture";
  for(@violations)
  {
    print $filereport "$path: $_";
  }
  close $filereport;
}
else
{
  print "Processing...\n";
  my $filereport;
  my $rule = Path::Iterator::Rule->new;
  $rule->perl_file;
  my $it = $rule->iter( $path );
  open ($filereport, '>', "./REPORT.txt") or die "Impossible d'ouvrir le fichier REPORT.txt en écriture";
  close $filereport;
  while ( my $file = $it->() ) 
  {
    @violations = critique( {-severity => 1}, "$file" );
    
    open ($filereport, '>>', "./REPORT.txt") or die "Impossible d'ouvrir le fichier REPORT.txt en écriture";
    for(@violations)
    {
      print $filereport "$file: $_";
    }
    close $filereport;
  }
  close $filereport;
}

1;