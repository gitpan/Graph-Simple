use Test::More;
use strict;

BEGIN
   {
   plan tests => 13;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Simple") or die($@);
   };

#############################################################################
my $graph = Graph::Simple->new();

is (ref($graph), 'Graph::Simple');

is ($graph->error(), '', 'no error yet');

is ($graph->nodes (), 0, '0 nodes');
is ($graph->edges (), 0, '0 edges');

my $bonn = Graph::Simple::Node->new( name => 'Bonn' );
my $berlin = Graph::Simple::Node->new( 'Berlin' );

$graph->add_edge ($bonn, $berlin);

is ($graph->nodes (), 2, '2 nodes added');
is ($graph->edges (), 1, '1 edge');

is ($graph->as_txt(), "[ Bonn ] --> [ Berlin ]\n", 'as_txt for 2 nodes');

is (ref($graph->edge($bonn,$berlin)), 'Graph::Simple::Edge', 'edge from objects');
is ($graph->edge($berlin,$bonn), undef, 'berlin not connecting to bonn');

is (ref($graph->edge('Bonn', 'Berlin')), 'Graph::Simple::Edge', 'edge from names');

#############################################################################

my $ffm = Graph::Simple::Node->new( name => 'Frankfurt a. M.' );
$graph->add_edge ($ffm, $bonn);

is ($graph->nodes (), 3, '3 nodes');
is ($graph->edges (), 2, '2 edges');

# print $graph->as_ascii();
