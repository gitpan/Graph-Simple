#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 65;
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
  class
  title
  del_attribute
  set_attribute
  set_attributes
  attribute
  attributes_as_txt
  attributes_as_graphviz
  as_pure_txt
  as_graphviz_txt
  group groups add_to_groups
  /);

#############################################################################

my $node = Graph::Simple::Node->new();

is (ref($node), 'Graph::Simple::Node');

is ($node->error(), '', 'no error yet');

is ($node->x(), 0, 'x == 0');
is ($node->y(), 0, 'x == 0');
is ($node->label(), 'Node #0', 'label');
is ($node->name(), 'Node #0', 'name');
is ($node->title(), '', 'no title per default');
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
is ($node->as_html(), "<td class='node'>Node #0</td>\n",
 'as_html');

# quoting of ()
$node->{name} = 'Frankfurt (Oder)';

is ($node->as_txt(), '[ Frankfurt \(Oder\) ]', 'as_txt');
is ($node->as_html(), "<td class='node'>Frankfurt (Oder)</td>\n",
 'as_html');

# quoting of []
$node->{name} = 'Frankfurt [ { #1 } ]';

is ($node->as_txt(), '[ Frankfurt \[ \{ \#1 \} \] ]', 'as_txt');
is ($node->as_html(), "<td class='node'>Frankfurt [ { #1 } ]</td>\n",
 'as_html');

# reset name
$node->{name} = 'Node #0';

#############################################################################
# as_txt/as_html w/ subclass and attributes

$node->{class} = 'node.cities';

is ($node->as_txt(), '[ Node \#0 ] { class: cities; }', 'as_txt');
is ($node->as_html(), "<td class='node-cities'>Node #0</td>\n",
 'as_html');
is ($node->as_pure_txt(), '[ Node \#0 ]', 'as_txt_node');

$node->set_attribute ( 'color', 'blue' );
is ($node->as_txt(), '[ Node \#0 ] { color: blue; class: cities; }', 'as_txt');
is ($node->as_html(), "<td class='node-cities' style=\"color: blue\">Node #0</td>\n",
 'as_html');
is ($node->as_pure_txt(), '[ Node \#0 ]', 'as_pure_txt');

$node->set_attribute ( 'padding', '1em' );
is ($node->as_txt(), '[ Node \#0 ] { color: blue; padding: 1em; class: cities; }', 'as_txt');
is ($node->as_html(), "<td class='node-cities' style=\"color: blue; padding: 1em\">Node #0</td>\n",
 'as_html');
is ($node->as_pure_txt(), '[ Node \#0 ]', 'as_pure_txt');

$node->set_attributes ( { padding => '2em', color => 'purple' } );
is ($node->as_txt(), '[ Node \#0 ] { color: purple; padding: 2em; class: cities; }', 'as_txt');
is ($node->as_html(), "<td class='node-cities' style=\"color: purple; padding: 2em\">Node #0</td>\n",
 'as_html');
is ($node->as_pure_txt(), '[ Node \#0 ]', 'as_pure_txt');

#############################################################################
# set_attributes(class => foo)

$node->set_attributes ( { class => 'foo', color => 'octarine' } );

is ($node->as_txt(), '[ Node \#0 ] { color: octarine; padding: 2em; class: foo; }', 'as_txt');
is ($node->as_html(), "<td class='node-foo' style=\"color: octarine; padding: 2em\">Node #0</td>\n",
 'as_html');

$node->set_attribute ( 'class', 'bar' );

is ($node->as_txt(), '[ Node \#0 ] { color: octarine; padding: 2em; class: bar; }', 'as_txt');
is ($node->as_html(), "<td class='node-bar' style=\"color: octarine; padding: 2em\">Node #0</td>\n",
 'as_html');

#############################################################################
# set_attribute() with encoded entities (%3a etc) and quotation marks

foreach my $l (
  'http://bloodgate.com/',
  '"http://bloodgate.com/"',
  '"http%3a//bloodgate.com/"',
  )
  {
  $node->set_attribute('link', $l);

  is ($node->as_txt(), 
    '[ Node \#0 ] { color: octarine; link: http://bloodgate.com/; padding: 2em; class: bar; }', 'as_txt');
  is ($node->as_html(), 
    "<td class='node-bar' style=\"color: octarine; padding: 2em\"> <a href='http://bloodgate.com/'>Node #0</a> </td>\n",
    'as_html');
  }

foreach my $l (
  'perl/',
  '"perl/"',
  )
  {
  $node->set_attribute('link', $l);

  is ($node->as_txt(), 
    '[ Node \#0 ] { color: octarine; link: perl/; padding: 2em; class: bar; }', 'as_txt');
  is ($node->as_html(), 
    "<td class='node-bar' style=\"color: octarine; padding: 2em\"> <a href='/wiki/index.php/perl/'>Node #0</a> </td>\n",
    'as_html');
  }

$node->set_attribute('link', "test test&");
  is ($node->as_txt(), 
    '[ Node \#0 ] { color: octarine; link: test test&; padding: 2em; class: bar; }', 'as_txt');
  is ($node->as_html(), 
    "<td class='node-bar' style=\"color: octarine; padding: 2em\"> <a href='/wiki/index.php/test+test&'>Node #0</a> </td>\n",
    'as_html');

$node->set_attribute('color', "\\#801010");
  is ($node->as_txt(), 
    '[ Node \#0 ] { color: #801010; link: test test&; padding: 2em; class: bar; }', 'as_txt');
  is ($node->as_html(), 
    "<td class='node-bar' style=\"color: #801010; padding: 2em\"> <a href='/wiki/index.php/test+test&'>Node #0</a> </td>\n",
    'as_html');

#############################################################################
# group tests

is ($node->groups(), 0, 'no groups yet');

is ($node->group('foo'), undef, 'no groups yet');
is ($node->groups(), 0, 'no groups yet');

use Graph::Simple::Group;

my $group = Graph::Simple::Group->new( { name => 'foo' } );
$node->add_to_groups($group);

is ($node->group('foo'), $group, 'group foo');
is ($node->groups(), 1, 'one group');

#############################################################################
# title tests

$node->set_attribute('title', "foo title");

is ($node->title(), 'foo title', 'foo title');

$node->del_attribute('title');
$node->set_attribute('autotitle', 'name');

is ($node->title(), $node->name(), 'title equals name');

#############################################################################
# invisible nodes

$node = Graph::Simple::Node->new( { name => "anon 0", label => 'X' } );
$node->set_attribute('shape', "invisible");

is ($node->as_ascii(), "", 'invisible text node');

