use Test::More;
use strict;

BEGIN
   {
   plan tests => 37;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Simple::Node") or die($@);
   use_ok ("Graph::Simple") or die($@);
   };

can_ok ("Graph::Simple::Node", qw/
  new
  as_ascii as_txt as_html
  error
  contains
  class
  name
  successors
  predecessors
  width
  height
  pos
  x
  y
  id
  class
  set_attribute
  set_attributes
  attribute
  /);

#############################################################################

my $node = Graph::Simple::Node->new();

is (ref($node), 'Graph::Simple::Node');

is ($node->error(), '', 'no error yet');

is ($node->x(), 0, 'x == 0');
is ($node->y(), 0, 'x == 0');
is ($node->id(), 0, 'id == 0');
is (join(",", $node->pos()), "0,0", 'pos = 0,0');
is ($node->width(), undef, 'w = undef');	# no graph => thus no width yet
is ($node->height(), 3, 'h = 3');

is (scalar $node->successors(), undef, 'no outgoing links');
is (scalar $node->predecessors(), undef, 'no incoming links');

my $edge = Graph::Simple::Node->new( class => 'edge', w => 19);

is ($edge->class(), 'edge', 'class edge');
is ($edge->width(), 19, 'specified w as 19');

my $other = Graph::Simple::Node->new();

#############################################################################
# predecessors() and successors() tests

my $graph = Graph::Simple->new( );

$other = Graph::Simple::Node->new( 'Name' );
$graph->add_edge ($node, $other);

is ($node->successors(), 1, '1 outgoing');
is ($node->predecessors(), 0, '0 incoming');

is ($other->successors(), 0, '0 outgoing');
is ($other->predecessors(), 1, '1 incoming');

#############################################################################
# as_txt/as_html

is ($node->as_txt(), '[ Node \#0 ]', 'as_txt');
is ($node->as_html(), "<td class='node'> Node #0 </td>\n",
 'as_html');

# quoting of ()
$node->{name} = 'Frankfurt (Oder)';

is ($node->as_txt(), '[ Frankfurt \(Oder\) ]', 'as_txt');
is ($node->as_html(), "<td class='node'> Frankfurt (Oder) </td>\n",
 'as_html');

# quoting of []
$node->{name} = 'Frankfurt [ { #1 } ]';

is ($node->as_txt(), '[ Frankfurt \[ \{ \#1 \} \] ]', 'as_txt');
is ($node->as_html(), "<td class='node'> Frankfurt [ { #1 } ] </td>\n",
 'as_html');

# reset name
$node->{name} = 'Node #0';

#############################################################################
# as_txt/as_html w/ subclass and attributes

$node->{class} = 'node.cities';

is ($node->as_txt(), '[ Node \#0 ] { class: cities; }', 'as_txt');
is ($node->as_html(), "<td class='node-cities'> Node #0 </td>\n",
 'as_html');

$node->set_attribute ( 'color', 'blue' );
is ($node->as_txt(), '[ Node \#0 ] { color: blue; class: cities; }', 'as_txt');
is ($node->as_html(), "<td class='node-cities' style=\"color: blue\"> Node #0 </td>\n",
 'as_html');

$node->set_attribute ( 'padding', '1em' );
is ($node->as_txt(), '[ Node \#0 ] { color: blue; padding: 1em; class: cities; }', 'as_txt');
is ($node->as_html(), "<td class='node-cities' style=\"color: blue; padding: 1em\"> Node #0 </td>\n",
 'as_html');

$node->set_attributes ( { padding => '2em', color => 'purple' } );
is ($node->as_txt(), '[ Node \#0 ] { color: purple; padding: 2em; class: cities; }', 'as_txt');
is ($node->as_html(), "<td class='node-cities' style=\"color: purple; padding: 2em\"> Node #0 </td>\n",
 'as_html');

#############################################################################
# set_attribute(class => foo)

$node->set_attributes ( { class => 'foo', color => 'octarine' } );

is ($node->as_txt(), '[ Node \#0 ] { color: octarine; padding: 2em; class: foo; }', 'as_txt');
is ($node->as_html(), "<td class='node-foo' style=\"color: octarine; padding: 2em\"> Node #0 </td>\n",
 'as_html');

$node->set_attribute ( 'class', 'bar' );

is ($node->as_txt(), '[ Node \#0 ] { color: octarine; padding: 2em; class: bar; }', 'as_txt');
is ($node->as_html(), "<td class='node-bar' style=\"color: octarine; padding: 2em\"> Node #0 </td>\n",
 'as_html');


