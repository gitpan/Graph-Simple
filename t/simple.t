use Test::More;
use strict;

BEGIN
   {
   plan tests => 12;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Simple") or die($@);
   };

can_ok ("Graph::Simple", qw/
  new
  css as_html as_html_page as_txt as_ascii
  html_page_header
  html_page_footer
  error
  node nodes edges
  add_edge
  add_node
  set_attributes
  attribute
  score
  id
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

#############################################################################
# attribute tests

is ($graph->attribute('node', 'background'), 'white', 
	'node { background: white }');

is ($graph->attribute('graph', 'border'), '1px solid black', 
	'graph { border: 1px solid black }');

$graph->set_attributes ('graph', { color => 'white', background => 'red' });

is ($graph->attribute('graph', 'background'), 'red', 
	'now: graph { background: red }');
is ($graph->attribute('graph', 'color'), 'white', 
	'now: graph { color: white }');

is ($graph->css(), <<HERE
.edge {
  background: inherit;
  border: none;
  margin: 0.1em;
  padding: 0.2em;
  text-align: center;
}
.graph {
  background: red;
  border: 1px solid black;
  color: white;
  margin: 0.5em;
  padding: 0.7em;
}
.node {
  background: white;
  border: 1px solid black;
  margin: 0.1em;
  padding: 0.2em;
  text-align: center;
}
HERE
, 'css()');

#############################################################################
# ID tests

is ($graph->id(), '', 'id is empty string');

is ($graph->id('42'), '42', 'id is now 42');

is ($graph->css(), <<HERE
.edge42 {
  background: inherit;
  border: none;
  margin: 0.1em;
  padding: 0.2em;
  text-align: center;
}
.graph42 {
  background: red;
  border: 1px solid black;
  color: white;
  margin: 0.5em;
  padding: 0.7em;
}
.node42 {
  background: white;
  border: 1px solid black;
  margin: 0.1em;
  padding: 0.2em;
  text-align: center;
}
HERE
, 'css()');


