use Test::More;
use strict;

BEGIN
   {
   plan tests => 10;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Simple::Parser") or die($@);
   };

can_ok ("Graph::Simple::Parser", qw/
  new
  from_text
  error
  /);

#############################################################################
# parser object

my $parser = Graph::Simple::Parser->new();

is (ref($parser), 'Graph::Simple::Parser');
is ($parser->error(), '', 'no error yet');

my $line = 0;

foreach (<DATA>)
  {
  chomp;
  next if $_ =~ /^\s*\z/;

  my ($in,$result) = split /\|/, $_;

  my $txt = $in;
  $txt =~ s/\\n/\n/g;				# insert real newlines

  my $graph = $parser->from_text($txt);		# reuse parser object
 
  my $got = scalar $graph->nodes();

  for my $n ( $graph->nodes() )
    {
    $got .= "," . $n->name();
    } 

  is ($got, $result, $in);
  }

__DATA__
|0
[ Berlin ]|1,Berlin
[Hamburg]|1,Hamburg
  [  Dresden  ]  |1,Dresden
[ Bonn ] -> [ Berlin ]|2,Berlin,Bonn
[ Bonn ] -> [ Berlin ]\n[Berlin] -> [Frankfurt]|3,Berlin,Bonn,Frankfurt

