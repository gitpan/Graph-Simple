use Test::More;
use strict;

BEGIN
   {
   plan tests => 10;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Simple::Group") or die($@);
   use_ok ("Graph::Simple") or die($@);
   };

can_ok ("Graph::Simple::Group", qw/
  new
  as_txt
  error
  name
  add_node
  add_nodes
  nodes
  id
  /);

#############################################################################

my $group = Graph::Simple::Group->new();

is (ref($group), 'Graph::Simple::Group');

is ($group->error(), '', 'no error yet');

is ($group->id(), 0, 'id == 0');

is ($group->as_txt(), 'Group #0 ( )', 'as_txt (empty group)');
is (scalar $group->nodes(), 0, 'no nodes in group');

my $first = Graph::Simple::Node->new();
my $second = Graph::Simple::Node->new();

$group->add_node($first);
is (scalar $group->nodes(), 1, 'one node in group');

$group->add_nodes($first, $second);
is (scalar $group->nodes(), 2, 'two nodes in group');


