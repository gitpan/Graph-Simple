use Test::More;
use strict;

BEGIN
   {
   plan tests => 22;
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

my $bonn = Graph::Simple::Node->new( name => 'Bonn' );
my $berlin = Graph::Simple::Node->new( 'Berlin' );

$graph->add_edge ($bonn, $berlin);

is ($graph->nodes(), 2, '2 nodes added');
is ($graph->edges(), 1, '1 edge');

is ($graph->as_txt(), "[ Bonn ] --> [ Berlin ]\n", 'as_txt for 2 nodes');

is (ref($graph->edge($bonn,$berlin)), 'Graph::Simple::Edge', 'edge from objects');
is ($graph->edge($berlin,$bonn), undef, 'berlin not connecting to bonn');

is (ref($graph->edge('Bonn', 'Berlin')), 'Graph::Simple::Edge', 'edge from names');

my @E = $graph->edges();

my $en = '';
for my $e (@E)
  {
  $en .= $e->{style} . '.';
  }

is ($en, '-->.', 'edges() in list context');

#############################################################################

my $ffm = Graph::Simple::Node->new( name => 'Frankfurt a. M.' );
$graph->add_edge ($ffm, $bonn);

is ($graph->nodes (), 3, '3 nodes');
is ($graph->edges (), 2, '2 edges');

# print $graph->as_ascii();

#############################################################################
# as_txt() (simple nodes)

is ( $graph->as_txt(), <<HERE
[ Bonn ] --> [ Berlin ]
[ Frankfurt a. M. ] --> [ Bonn ]
HERE
, 'as_txt() for 3 nodes with 2 edges');

my $schweinfurt = Graph::Simple::Node->new( name => 'Schweinfurt' );
$graph->add_edge ($schweinfurt, $bonn);

is ($graph->nodes (), 4, '4 nodes');
is ($graph->edges (), 3, '3 edges');

is ( $graph->as_txt(), <<HERE
[ Bonn ] --> [ Berlin ]
[ Frankfurt a. M. ] --> [ Bonn ]
[ Schweinfurt ] --> [ Bonn ]
HERE
, 'as_txt() for 3 nodes with 2 edges');

#############################################################################
# as_txt() (nodes with attributes)

$bonn->set_attribute('class', 'cities');

is ( $graph->as_txt(), <<HERE
[ Bonn ] { class: cities; }
[ Bonn ] --> [ Berlin ]
[ Frankfurt a. M. ] --> [ Bonn ]
[ Schweinfurt ] --> [ Bonn ]
HERE
, 'as_txt() for 3 nodes with 2 edges');

$bonn->set_attribute('border', 'none');
$bonn->set_attribute('color', 'red');
$berlin->set_attribute('color', 'blue');

# class is always the last attribute:

is ( $graph->as_txt(), <<HERE
[ Berlin ] { color: blue; }
[ Bonn ] { border: none; color: red; class: cities; }
[ Bonn ] --> [ Berlin ]
[ Frankfurt a. M. ] --> [ Bonn ]
[ Schweinfurt ] --> [ Bonn ]
HERE
, 'as_txt() for 3 nodes with 2 edges');


$graph->set_attribute('graph', 'border', 'none');
$graph->set_attribute('edge', 'border', 'blue solid 1px');

# graph/node/edge attributes come first

is ( $graph->as_txt(), <<HERE
edge { border: blue solid 1px; }
graph { border: none; }
[ Berlin ] { color: blue; }
[ Bonn ] { border: none; color: red; class: cities; }
[ Bonn ] --> [ Berlin ]
[ Frankfurt a. M. ] --> [ Bonn ]
[ Schweinfurt ] --> [ Bonn ]
HERE
, 'as_txt() for 3 nodes with 2 edges');


