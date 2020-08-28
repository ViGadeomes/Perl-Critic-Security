package CWExxx_DefaultVariableInForeach;

sub BAD1()
{
  my @list = (0, 'test', 10);
  
  for(@list)
  {
    print "$_\n";
  }
}

sub BAD2()
{
  my @list = (0, 'test', 10);
  
  foreach (@list)
  {
    print "$_\n";
  }
}

sub GOOD1()
{
  my @list = (0, 'test', 10);
  
  for my $value(@list)
  {
    print "$value\n";
  }
}

sub GOOD2()
{
  my @list = (0, 'test', 10);
  
  my $value;
  
  for $value  (@list)
  {
    print "$value\n";
  }
}