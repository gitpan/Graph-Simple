#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 11;
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

my $html = $graph->as_html();

like ($html, qr/<table/, 'looks like HTML to me');

#############################################################################
# with some nodes

my $bonn = Graph::Simple::Node->new( name => 'Bonn' );
my $berlin = Graph::Simple::Node->new( 'Berlin' );

$graph->add_edge ($bonn, $berlin);

$html = $graph->as_html();

like ($html, qr/Bonn/, 'contains Bonn');
like ($html, qr/Berlin/, 'contains Bonn');

#############################################################################
# with some nodes with atributes

$bonn->set_attribute( 'autotitle' => 'name' );

$html = $graph->as_html();

like ($html, qr/title="Bonn"/, 'contains title="Bonn"');
unlike ($html, qr/title="Berlin"/, "doesn't contains title Berlin");

#print $graph->as_svg(),"\n";

