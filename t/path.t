use Test::More;
use strict;

BEGIN
   {
   plan tests => 14;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Simple::Path") or die($@);
   use_ok ("Graph::Simple") or die($@);
   };

can_ok ("Graph::Simple::Path", qw/
  new
  as_ascii as_html
  error
  pos
  x
  y
  /);

use Graph::Simple::Path qw/EDGE_SHORT_W/;
use Graph::Simple::Edge;

#############################################################################

my $path = Graph::Simple::Path->new();

is (ref($path), 'Graph::Simple::Path');

is ($path->error(), '', 'no error yet');

is ($path->x(), 0, 'x == 0');
is ($path->y(), 0, 'x == 0');
is ($path->label(), '', 'label');
is (join(",", $path->pos()), "0,0", 'pos = 0,0');
is ($path->width(), undef, 'w = undef');	# no graph => thus no width yet

$path = Graph::Simple::Path->new( type => EDGE_SHORT_W);

is ($path->type(), EDGE_SHORT_W, 'edge to the left');

#############################################################################
# attribute()

my $edge = Graph::Simple::Edge->new();

$edge->set_attribute( color => 'blue', border => 'none');

$path = Graph::Simple::Path->new( type => EDGE_SHORT_W, edge => $edge);

is ($path->attribute('color'), 'blue');

#############################################################################
# as_txt/as_html

#print $path->as_ascii();
#print $path->as_html();

is ($path->as_ascii(), "\n <--\n", 'as ascii');
is ($path->as_html(), "<td class='edge'>&lt;------<\/td>\n", 'as html');

