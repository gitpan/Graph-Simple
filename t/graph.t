use Test::More;

BEGIN
   {
   plan tests => 8;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Simple") or die($@);
   };

#############################################################################
my $graph = Graph::Simple->new();

is (ref($graph), 'Graph::Simple');

is ($graph->error(), '', 'no error yet');

my $bonn = Graph::Simple::Node->new( name => 'Bonn' );
my $berlin = Graph::Simple::Node->new( 'Berlin' );

$graph->add_edge ($bonn, $berlin);

is ($graph->nodes (), 2, '2 nodes added');

is ($graph->as_txt(), "[ Bonn ] --> [ Berlin ]\n", 'as_txt for 2 nodes');

is (ref($graph->edge($bonn,$berlin)), 'Graph::Simple::Edge', 'edge from objects');
is ($graph->edge($berlin,$bonn), undef, 'berlin not connecting to bonn');

is (ref($graph->edge('Bonn', 'Berlin')), 'Graph::Simple::Edge', 'edge from names');

# print $graph->as_ascii();
