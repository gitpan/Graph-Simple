use Test::More;
use strict;

BEGIN
   {
   plan tests => 12;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Simple::Layout") or die($@);
   };

can_ok ("Graph::Simple", qw/
  _trace_path
  _trace_straight_path
  _remove_path
  _put_path
  /);

isnt ($Graph::Simple::VERSION, undef, 'VERSION in Layout');

use Graph::Simple;

Graph::Simple::Path->import (qw/EDGE_HOR EDGE_VER/);

#############################################################################
# layout tests

my $graph = Graph::Simple->new();

is (ref($graph), 'Graph::Simple');

is ($graph->error(), '', 'no error yet');

#############################################################################
# _trace_straight_path()

my $src = Graph::Simple::Node->new( name => 'Bonn' );
my $dst = Graph::Simple::Node->new( 'Berlin' );

$src->{x} = 1; $src->{y} = 1;
$dst->{x} = 1; $dst->{y} = 1;

my @coords = $graph->_trace_straight_path( $src, $dst);

is (scalar @coords, 2+1, 'same cell => sort edge path');


$src->{x} = 1; $src->{y} = 1;
$dst->{x} = 2; $dst->{y} = 2;

@coords = $graph->_trace_straight_path( $src, $dst);

is (scalar @coords, 0, 'no straight path');


# mark one cell as already occupied
$graph->{cells}->{"1,2"} = $src;

$src->{x} = 1; $src->{y} = 1;
$dst->{x} = 1; $dst->{y} = 3;

@coords = $graph->_trace_straight_path( $src, $dst);

is (scalar @coords, 0, 'cell already occupied');

delete $graph->{cells}->{"1,2"};

@coords = $graph->_trace_straight_path( $src, $dst);

is (scalar @coords, 2+1, 'straight path down');
is (join (":", @coords), '0:1:1,2,' . EDGE_VER(), 'path 1,1 => 1,3');

$src->{x} = 1; $src->{y} = 0;
$dst->{x} = 1; $dst->{y} = 5;

@coords = $graph->_trace_straight_path( $src, $dst);

is (scalar @coords, 2+4, 'straight path down');
my $type = EDGE_VER();
is (join (":", @coords), "0:1:1,1,$type:1,2,$type:1,3,$type:1,4,$type", 'path 1,0 => 1,5');


