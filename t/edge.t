use Test::More;
use strict;

BEGIN
   {
   plan tests => 11;
   chdir 't' if -d 't';
   use lib '../lib';
   }

use Exporter;

use Graph::Simple::Edge qw/
   EDGE_START 
   EDGE_SHORT 
   EDGE_CROSS
   EDGE_SHORT
   EDGE_END
   EDGE_VER
   EDGE_HOR
  /;

can_ok ("Graph::Simple::Edge", qw/
  new
  as_ascii as_txt
  error
  name
  to_nodes
  from_nodes
  nodes
  cells
  add_cell
  cell_type
  /);

#############################################################################

my $edge = Graph::Simple::Edge->new();

is (ref($edge), 'Graph::Simple::Edge');

is ($edge->error(), '', 'no error yet');

is ($edge->as_txt(), ' --> ', 'default is "-->"');
is ($edge->as_ascii(), '-->', 'default is "-->"');

#############################################################################
# different styles

$edge = Graph::Simple::Edge->new( style => '==>' );

is ($edge->as_txt(), ' ==> ', '"==>"');
is ($edge->as_ascii(), '==>', '"==>"');

#############################################################################
# cells

is (scalar keys %{$edge->cells()}, 0, 'no cells');

$edge->add_cell(0,0,EDGE_END());
is (scalar keys %{$edge->cells()}, 1, 'one cell');

$edge->add_cell(0,0,EDGE_START());
is (scalar keys %{$edge->cells()}, 1, 'still one cell');

$edge->add_cell(1,1,EDGE_END());
is (scalar keys %{$edge->cells()}, 2, 'two cells');

