use Test::More;
use strict;

BEGIN
   {
   plan tests => 19;
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
  name
  successors
  predecessors
  width
  height
  pos
  x
  y
  id
  /);

#############################################################################

my $node = Graph::Simple::Node->new();

is (ref($node), 'Graph::Simple::Node');

is ($node->error(), '', 'no error yet');

is ($node->x(), 0, 'x == 0');
is ($node->y(), 0, 'x == 0');
is ($node->id(), 0, 'id == 0');
is (join(",", $node->pos()), "0,0", 'pos = 0,0');
is ($node->width(), 11, 'w = 11');
is ($node->height(), 3, 'h = 3');

is (scalar $node->successors(), undef, 'no outgoing links');
is (scalar $node->predecessors(), undef, 'no incoming links');

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









