#!/usr/bin/perl -w

use Test::More;
use strict;

# test text file input => ASCII output and back to as_txt() again

BEGIN
   {
   plan tests => 25;
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
  $txt =~ s/(^|\n)\s*#.*\n//g;			# remove comments
  $txt =~ s/\n\n/\n/g;				# remove empty lines
 
  $f =~ /^(\d+)/;
  my $nodes = $1;

  is (scalar $graph->nodes(), $nodes, "$nodes nodes");

  my $ascii = $graph->as_ascii();
  my $out = readfile("out/$f");
  $out =~ s/(^|\n)\s*#.*\n//g;			# remove comments
  $out =~ s/\n\n/\n/g;				# remove empty lines

#  print "txt: $txt\n";
# print "ascii: $ascii\n";
# print "should: $out\n";

  is ($ascii, $out, "from $f");

  # if the txt output differes, read it in
  if (-f "txt/$f")
    {
    $txt = readfile("txt/$f");
    }
  else
    {
    # input might have whitespace at front, remove it because output doesn't
    $txt =~ s/(^|\n)\s+/$1/g;
    }

  if (!
    is ($graph->as_txt(), $txt, "$f as_txt"))
    {
    require Test::Differences;

    if (defined $Test::Differences::VERSION)
      {
      Test::Differences::eq_or_diff ($graph->as_txt(), $txt);
      }
    }

  # print a debug output
  my $debug = $ascii;
  $debug =~ s/\n/\n# /g;
  print "# Generated:\n#\n# $debug\n";
  }

1;

sub readfile
  {
  my ($file) = @_;

  open FILE, $file or die ("Cannot read file $file: $!");
  local $/ = undef;				# slurp mode
  my $doc = <FILE>;
  close FILE;

  $doc;
  }
