use Test::More;
use strict;

# test text file input => ASCII output and back to as_txt() again

BEGIN
   {
   plan tests => 16;
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
  next unless -f "in/$f";			# only files

  print "# at $f\n";
  my $txt = readfile("in/$f");
  my $graph = $parser->from_text($txt);		# reuse parser object

  $txt =~ s/\n\s+/\n/;				# remove trailing whitespace
 
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
  #$txt =~ s/[=-]+>/-->/g;			# normalize arrows

  # input might have whitespace at front, remove it because output doesn't
  $txt =~ s/(^|\n)\s+/$1/g;

  is ($graph->as_txt(), $txt, "$f as_txt");

  # print a debug output
  my $debug = $ascii;
  $debug =~ s/\n/\n# /g;
  print "# Generated:\n#\n# $debug\n";
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
