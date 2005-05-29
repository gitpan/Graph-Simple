#!/usr/bin/perl -w

# parser.t does general parser tests, this one deals only with "[A|B|C]" style
# nodes and tests that this feature does work correctly.

use Test::More;
use strict;

BEGIN
   {
   plan tests => 21;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Simple::Parser") or die($@);
   };

can_ok ("Graph::Simple::Parser", qw/
  new
  from_text
  from_file
  reset
  error
  _parse_attributes
  /);

#############################################################################
# parser object

my $parser = Graph::Simple::Parser->new();

is (ref($parser), 'Graph::Simple::Parser');
is ($parser->error(), '', 'no error yet');


#############################################################################
# split a node and check all relevant fields

my $graph = $parser->from_text("[A|B|C]");

is (scalar $graph->nodes(), 3, '3 nodes');
is (scalar $graph->clusters(), 1, '1 cluster');

my $A = $graph->node('ABC.0');
is (ref($A), 'Graph::Simple::Node', 'node is node');
is ($A->origin(), undef, 'A is the origin itself');

my $B = $graph->node('ABC.1');
is (ref($B), 'Graph::Simple::Node', 'node is node');
is ($B->origin(), $A, 'A is the origin of B');
is (join(",", $B->relpos()), "1,0", 'B is at +1,0');

my $C = $graph->node('ABC.2');
is (ref($C), 'Graph::Simple::Node', 'node is node');
is ($C->origin(), $A, 'A is the origin of C');
is (join(",", $C->relpos()), "2,0", 'C is at +2,0');

#############################################################################
# general split tests

my $line = 0;

foreach (<DATA>)
  {
  chomp;
  next if $_ =~ /^\s*\z/;			# skip empty lines
  next if $_ =~ /^#/;				# skip comments

  die ("Illegal line $line in testdata") unless $_ =~ /^(.*)\|([^\|]*)$/;
  my ($in,$result) = ($1,$2);

  my $txt = $in;
  $txt =~ s/\\n/\n/g;				# insert real newlines

  Graph::Simple::Node->_reset_id();		# to get "#0" for each test
  my $graph = $parser->from_text($txt);		# reuse parser object

  if (!defined $graph)
    {
    fail($parser->error());
    next;
    }
 
  my $got = scalar $graph->nodes();

  my @edges = $graph->edges();

  my $es = 0;
  foreach my $e (sort { $a->label() cmp $b->label() } @edges)
    {
    $es ++ if $e->label() ne '';
    }

  $got .= '+' . $es if $es > 0;

  for my $n ( sort { $a->{name} cmp $b->{name} } ($graph->nodes(), $graph->edges()) )
    {
    $got .= ";" . $n->name() . "," . $n->label() . "=$n->{dx}.$n->{dy}." . $n->attribute('background');
    } 
  
  is ($got, $result, $in);
  }

__DATA__
# split tests with attributes
[A|B|C]|3;ABC.0,A=0.0.white;ABC.1,B=1.0.white;ABC.2,C=2.0.white
[A|B|C] { background: red; }|3;ABC.0,A=0.0.red;ABC.1,B=1.0.red;ABC.2,C=2.0.red
[A|B|C] { label: foo; background: red; }|3;ABC.0,foo=0.0.red;ABC.1,foo=1.0.red;ABC.2,foo=2.0.red
[A| |C]|3;AC.0,A=0.0.white;AC.1,=1.0.white;AC.2,C=2.0.white
[A||B|C]|3;ABC.0,A=0.0.white;ABC.1,B=0.1.white;ABC.2,C=1.1.white
[A||B||C]|3;ABC.0,A=0.0.white;ABC.1,B=0.1.white;ABC.2,C=0.2.white
[A|| |C]|3;AC.0,A=0.0.white;AC.1,=0.1.white;AC.2,C=1.1.white

