use Test::More;
use strict;

# test text file input => ASCII output and back to as_txt() again

BEGIN
   {
   plan tests => 13;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Simple") or die($@);
   use_ok ("Graph::Simple::Parser") or die($@);
   };

#############################################################################
# parser object

my $parser = Graph::Simple::Parser->new( debug => 0);

is (ref($parser), 'Graph::Simple::Parser');
is ($parser->error(), '', 'no error yet');

opendir DIR, "in" or die ("Cannot read dir 'in': $!");
my @files = readdir(DIR); closedir(DIR);

foreach my $f (@files)
  {
  print "at $f\n";
  next unless -f "in/$f";			# only files

  my $txt = readfile("in/$f");
  my $graph = $parser->from_text($txt);		# reuse parser object

  $f =~ /^(\d+)/;
  my $nodes = $1;

  is (scalar $graph->nodes(), $nodes, "$nodes nodes");

  my $ascii = $graph->as_ascii();
  my $out = readfile("out/$f");

#  print "txt: $txt\n";
# print "ascii: $ascii\n";
# print "should: $out\n";

  is ($ascii, $out, "from $f");

  # XXX TODO
  $txt =~ s/[=-]+>/-->/g;			# normalize arrows

  is ($graph->as_txt(), $txt, "$f as_txt")
  }

1;

sub readfile
  {
  my ($file) = @_;

  open FILE, $file or die ("Cannot read file $file: $1");
  local $/ = undef;				# slurp mode
  my $doc = <FILE>;
  close FILE;

  $doc;
  }
