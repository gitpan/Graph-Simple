use Test::More;
use strict;

BEGIN
   {
   plan tests => 23;
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
  set_attribute
  attribute
  score
  id
  group groups add_group del_group
  /);

use Graph::Simple::Group;

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

is ($graph->attribute('graph', 'border'), 'none', 
	'graph { border: none; }');

$graph->set_attributes ('graph', { color => 'white', background => 'red' });

is ($graph->attribute('graph', 'background'), 'red', 
	'now: graph { background: red }');
is ($graph->attribute('graph', 'color'), 'white', 
	'now: graph { color: white }');

is ($graph->css(), <<HERE
.edge {
  background: inherit;
  border: none;
  font-family: monospaced, courier-new, courier, sans-serif;
  letter-spacing: -0.36em;
  line-height: 0.7em;
  margin: 0.1em;
  padding: 0.2em;
  padding-right: 0.4em;
  text-align: center;
}
.graph {
  background: red;
  border: none;
  color: white;
  margin: 0.5em;
  padding: 0.7em;
}
.group {
  border: 1px dashed black;
}
.node {
  background: white;
  border: 1px solid black;
  margin: 0.1em;
  padding: 0.2em;
  padding-left: 0.3em;
  padding-right: 0.3em;
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
  font-family: monospaced, courier-new, courier, sans-serif;
  letter-spacing: -0.36em;
  line-height: 0.7em;
  margin: 0.1em;
  padding: 0.2em;
  padding-right: 0.4em;
  text-align: center;
}
.graph42 {
  background: red;
  border: none;
  color: white;
  margin: 0.5em;
  padding: 0.7em;
}
.group42 {
  border: 1px dashed black;
}
.node42 {
  background: white;
  border: 1px solid black;
  margin: 0.1em;
  padding: 0.2em;
  padding-left: 0.3em;
  padding-right: 0.3em;
  text-align: center;
}
HERE
, 'css() with id');


#############################################################################
# ID tests with sub-classes

$graph->set_attributes ('node.cities', { color => '#808080' } );

is ($graph->css(), <<HERE
.edge42 {
  background: inherit;
  border: none;
  font-family: monospaced, courier-new, courier, sans-serif;
  letter-spacing: -0.36em;
  line-height: 0.7em;
  margin: 0.1em;
  padding: 0.2em;
  padding-right: 0.4em;
  text-align: center;
}
.graph42 {
  background: red;
  border: none;
  color: white;
  margin: 0.5em;
  padding: 0.7em;
}
.group42 {
  border: 1px dashed black;
}
.node42,.node-cities42 {
  background: white;
  border: 1px solid black;
  margin: 0.1em;
  padding: 0.2em;
  padding-left: 0.3em;
  padding-right: 0.3em;
  text-align: center;
}
.node-cities42 {
  color: #808080;
}
HERE
, 'css() with sub-classes');

#############################################################################
# group tests

is ($graph->groups(), 0, 'no groups yet');

is ($graph->group('foo'), undef, 'no groups yet');
is ($graph->groups(), 0, 'no groups yet');

my $group = Graph::Simple::Group->new( { name => 'Cities' } );
$graph->add_group($group);

is ($graph->group('Cities'), $group, "group 'cities'");
is ($graph->groups(), 1, 'one group');
is ($graph->group('cities'), undef, 'no group');
is ($graph->groups(), 1, 'one group');

is ($graph->as_txt(), <<HERE
graph {
  color: white;
  background: red;
}
node.cities { color: #808080; }

( Cities
)

[ Bonn ] --> [ Berlin ]
[ Berlin ] --> [ Potsdam ]
[ Berlin ] --> [ Frankfurt ]
[ Frankfurt ] --> [ Dresden ]
[ Potsdam ] --> [ Cottbus ]
HERE
, 'with empty group Cities'); 

$node->add_to_groups($group);

is ($graph->as_txt(), <<HERE
graph {
  color: white;
  background: red;
}
node.cities { color: #808080; }

( Cities
  [ Bonn ]
)

[ Bonn ] --> [ Berlin ]
[ Berlin ] --> [ Potsdam ]
[ Berlin ] --> [ Frankfurt ]
[ Frankfurt ] --> [ Dresden ]
[ Potsdam ] --> [ Cottbus ]
HERE
, 'with empty group Cities'); 


#############################################################################
# title/link/autolink/autotitle/linkbase not in CSS

$graph->set_attributes ('node', 
  { link => 123, title => 123, autolink => 'name', autotitle => 'name' } );
$graph->set_attributes ('graph', { linkbase => '123/' } );

is ($graph->css(), <<HERE
.edge42 {
  background: inherit;
  border: none;
  font-family: monospaced, courier-new, courier, sans-serif;
  letter-spacing: -0.36em;
  line-height: 0.7em;
  margin: 0.1em;
  padding: 0.2em;
  padding-right: 0.4em;
  text-align: center;
}
.graph42 {
  background: red;
  border: none;
  color: white;
  margin: 0.5em;
  padding: 0.7em;
}
.group42 {
  border: 1px dashed black;
}
.node42,.node-cities42 {
  background: white;
  border: 1px solid black;
  margin: 0.1em;
  padding: 0.2em;
  padding-left: 0.3em;
  padding-right: 0.3em;
  text-align: center;
}
.node-cities42 {
  color: #808080;
}
HERE
, 'css() with non-css attributes link|title|linkbase etc');



