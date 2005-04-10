#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 12;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Simple") or die($@);
   };

#############################################################################
my $graph = Graph::Simple->new();

is (ref($graph), 'Graph::Simple');

is ($graph->error(), '', 'no error yet');

is ($graph->nodes(), 0, '0 nodes');
is ($graph->edges(), 0, '0 edges');

is (join (',', $graph->edges()), '', '0 edges');

like ($graph->as_graphviz(), qr/digraph.*\{/, 'looks like digraph');

#############################################################################
# with some nodes

my $bonn = Graph::Simple::Node->new( name => 'Bonn' );
my $berlin = Graph::Simple::Node->new( 'Berlin' );

$graph->add_edge ($bonn, $berlin);

like ($graph->as_graphviz(), qr/"Bonn"/, 'contains Bonn');
like ($graph->as_graphviz(), qr/"Berlin"/, 'contains Bonn');

#print $graph->as_graphviz(),"\n";

#############################################################################
# with some nodes with atributes

$bonn->set_attribute( 'shape' => 'box' );

like ($graph->as_graphviz(), qr/"Bonn"/, 'contains Bonn');
like ($graph->as_graphviz(), qr/"Berlin"/, 'contains Bonn');
like ($graph->as_graphviz(), qr/shape=box/, 'contains shape');

#print $graph->as_graphviz(),"\n";

