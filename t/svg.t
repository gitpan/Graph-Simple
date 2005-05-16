#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 14;
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

my $svg = $graph->as_svg();

like ($svg, qr/enerated by/, 'looks like SVG');
like ($svg, qr/<svg/, 'looks like SVG');
like ($svg, qr/<\/svg/, 'looks like SVG');

#############################################################################
# with some nodes

my $bonn = Graph::Simple::Node->new( name => 'Bonn' );
my $berlin = Graph::Simple::Node->new( 'Berlin' );

$graph->add_edge ($bonn, $berlin);

like ($graph->as_svg(), qr/Bonn/, 'contains Bonn');
like ($graph->as_svg(), qr/Berlin/, 'contains Berlin');

#print $graph->as_svg(),"\n";

#############################################################################
# with some nodes with atributes

$bonn->set_attribute( 'shape' => 'circle' );

like ($graph->as_svg(), qr/Bonn/, 'contains Bonn');
like ($graph->as_svg(), qr/Berlin/, 'contains Bonn');
like ($graph->as_svg(), qr/circle/, 'contains shape');

#print $graph->as_svg(),"\n";

