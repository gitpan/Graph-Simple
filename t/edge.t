use Test::More;
use strict;

BEGIN
   {
   plan tests => 12;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok qw/Graph::Simple::Edge/;
   use_ok qw/Graph::Simple::Path/;
   }

can_ok ("Graph::Simple::Edge", qw/
  new
  as_txt
  error
  label
  cells
  add_cell
  clear_cells
  attribute
  set_attribute
  set_attributes
  groups
  /);
  
use Graph::Simple::Path qw/EDGE_SHORT_E/;

#############################################################################

my $edge = Graph::Simple::Edge->new();

is (ref($edge), 'Graph::Simple::Edge');

is ($edge->error(), '', 'no error yet');

is ($edge->as_txt(), ' --> ', 'default is "-->"');

#############################################################################
# different styles

$edge = Graph::Simple::Edge->new( style => '==' );

is ($edge->as_txt(), ' ==> ', '"==>"');

#############################################################################
# cells

is (scalar keys %{$edge->cells()}, 0, 'no cells');

my $path = Graph::Simple::Path->new (
  type => EDGE_SHORT_E,
  x => 1, y => 1,
);

$edge->add_cell($path);
is (scalar keys %{$edge->cells()}, 1, 'one cell');

$edge->add_cell($path);
is (scalar keys %{$edge->cells()}, 1, 'still one cell');

$path->{x}++;
$edge->add_cell($path);
is (scalar keys %{$edge->cells()}, 2, 'two cells');

$edge->clear_cells();
is (scalar keys %{$edge->cells()}, 0, 'no cells');

