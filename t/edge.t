use Test::More;
use strict;

BEGIN
   {
   plan tests => 9;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Simple::Edge") or die($@);
   use_ok ("Graph::Simple") or die($@);
   };

can_ok ("Graph::Simple::Edge", qw/
  new
  as_ascii as_txt
  error
  name
  to_nodes
  from_nodes
  nodes
  cells
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


