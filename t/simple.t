use Test::More;
use strict;

BEGIN
   {
   plan tests => 4;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Simple") or die($@);
   };

can_ok ("Graph::Simple", qw/
  new
  as_ascii
  error
  add_edge
  nodes
  vertices
  add_node
  score
  /);

#############################################################################
# layout tests

my $graph = Graph::Simple->new();

is (ref($graph), 'Graph::Simple');

is ($graph->error(), '', 'no error yet');

my $node = Graph::Simple::Node->new( name => 'Bonn' );
my $node2 = Graph::Simple::Node->new( name => 'Berlin' );

$graph->add_edge( $node, $node2 );

#print $graph->as_ascii();

$graph->{debug} = 0;

my $node3 = Graph::Simple::Node->new( name => 'Frankfurt', border => 'dotted' );

$graph->add_edge( $node2, $node3 );

#print $graph->as_ascii();

my $node4 = Graph::Simple::Node->new( name => 'Dresden' );

$graph->add_edge( $node3, $node4 );

#print $graph->as_ascii();

my $node5 = Graph::Simple::Node->new( name => 'Potsdam' );

$graph->add_edge( $node2, $node5 );

#print $graph->as_ascii();

my $node6 = Graph::Simple::Node->new( name => 'Cottbus' );

$graph->add_edge( $node5, $node6 );

#print $graph->as_ascii();

