use Test::More;

BEGIN
   {
   plan tests => 17;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Simple::Node") or die($@);
   use_ok ("Graph::Simple") or die($@);
   };

can_ok ("Graph::Simple::Node", qw/
  new
  as_ascii
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
  /);

#############################################################################

my $node = Graph::Simple::Node->new();

is (ref($node), 'Graph::Simple::Node');

is ($node->error(), '', 'no error yet');

is ($node->x(), 0, 'x = 0');
is ($node->y(), 0, 'x = 0');
is (join(",", $node->pos()), "0,0", 'pos = 0,0');
is ($node->width(), 10, 'w = 10');
is ($node->height(), 3, 'h = 3');

is ($node->as_txt(), '[ Sample ]', 'as_txt');
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

