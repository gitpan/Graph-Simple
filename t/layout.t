use Test::More;
use strict;

BEGIN
   {
   plan tests => 5;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Simple::Layout") or die($@);
   };

can_ok ("Graph::Simple", qw/
  _trace_path
  _trace_straight_path
  _remove_path
  _gen_edge_left
  _gen_edge_right
  _gen_edge_up
  _gen_edge_down
  /);

isnt ($Graph::Simple::VERSION, undef, 'VERSION in Layout');

use Graph::Simple;

#############################################################################
# layout tests

my $graph = Graph::Simple->new();

is (ref($graph), 'Graph::Simple');

is ($graph->error(), '', 'no error yet');


