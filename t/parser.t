#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 51;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Simple::Parser") or die($@);
   };

can_ok ("Graph::Simple::Parser", qw/
  new
  from_text
  from_file
  reset
  error
  _parse_attributes
  /);

#############################################################################
# parser object

my $parser = Graph::Simple::Parser->new();

is (ref($parser), 'Graph::Simple::Parser');
is ($parser->error(), '', 'no error yet');

#############################################################################
# matching nodes

my $node_qr = $parser->_match_node();

like ('[]', $node_qr, '[] is a node');
like ('[ ]', $node_qr, '[ ] is a node');

#############################################################################
# general pattern tests

my $line = 0;

foreach (<DATA>)
  {
  chomp;
  next if $_ =~ /^\s*\z/;			# skip empty lines
  next if $_ =~ /^#/;				# skip comments

  my ($in,$result) = split /\|/, $_;

  my $txt = $in;
  $txt =~ s/\\n/\n/g;				# insert real newlines

  Graph::Simple::Node->_reset_id();		# to get "#0" for each test
  my $graph = $parser->from_text($txt);		# reuse parser object

  if (!defined $graph)
    {
    fail($parser->error());
    next;
    }
 
  my $got = scalar $graph->nodes();

  my @edges = $graph->edges();

  my $es = 0;
  foreach my $e (sort { $a->label() cmp $b->label() } @edges)
    {
    $es ++ if $e->label() ne '';
    }

  $got .= '+' . $es if $es > 0;

  for my $n ( sort { $a->{name} cmp $b->{name} } ($graph->nodes(), $graph->edges()) )
    {
    $got .= "," . $n->label() unless $n->label() eq '';
    } 
  
  is ($got, $result, $in);
  }

__DATA__
|0
# anon nodes
[]|1,#0
[]->[]|2,#0,#1
[Bonn]->[]|2,#1,Bonn
[]->[Bonn]|2,#0,Bonn
[]->[Bonn]->[]|3,#0,#2,Bonn
# normal tests
[ Berlin ]|1,Berlin
[Hamburg]|1,Hamburg
  [  Dresden  ]  |1,Dresden
[ Pirna ] { color: red; }|1,Pirna
[ Bonn ] -> [ Berlin ]|2,Berlin,Bonn
[ Bonn ] -> [ Berlin ]\n[Berlin] -> [Frankfurt]|3,Berlin,Bonn,Frankfurt
[ Bonn ] ==> [ Berlin ]\n[Berlin] -> [Frankfurt]|3,Berlin,Bonn,Frankfurt
[ Bonn ] ..> [ Berlin ]\n[Berlin] -> [Frankfurt]|3,Berlin,Bonn,Frankfurt
[ Bonn ] - > [ Berlin ]\n[Berlin] -> [Frankfurt]|3,Berlin,Bonn,Frankfurt
[ Bonn \( \#1 \) ] - > [ Berlin ]\n[Berlin] -> [Frankfurt]|3,Berlin,Bonn ( #1 ),Frankfurt
[ Bonn ] { color: red; }\n[Berlin] -> [Frankfurt]|3,Berlin,Bonn,Frankfurt
[Bonn]{color:red;}\n[Berlin]->[Frankfurt]|3,Berlin,Bonn,Frankfurt
[ Bonn ] { color: red; } -> [ Berlin ]\n[Berlin] -> [Frankfurt]|3,Berlin,Bonn,Frankfurt
[ Bonn ] { color: red; } -> [ Berlin ] {color: blue} \n[Berlin] -> [Frankfurt]|3,Berlin,Bonn,Frankfurt
[ Bonn ] { color: #fff; } -> [ Berlin ] { color: #A0a0A0 } # failed in v0.09 [ Bonn ] -> [ Ulm ]|2,Berlin,Bonn
[ Bonn ] { color: #fff; } -> [ Berlin ] { color: #A0a0A0 } #80808080 failed in v0.09 [ Bonn ] -> [ Ulm ]|2,Berlin,Bonn
[ Bonn ] { color: #fff; } -> [ Berlin ] { color: #A0a0A0 } #808080 failed in v0.09 [ Bonn ] -> [ Ulm ]|2,Berlin,Bonn
# node chains
[ Bonn ] -> [ Berlin ]\n -> [ Kassel ]|3,Berlin,Bonn,Kassel
[ Bonn ] { color: #fff; } -> [ Berlin ] { color: #A0a0A0 }\n -> [ Kassel ] { color: red; }|3,Berlin,Bonn,Kassel
[ Bonn ] -> [ Berlin ] -> [ Kassel ]|3,Berlin,Bonn,Kassel
[ Bonn ] { color: #fff; } -> [ Berlin ] { color: #A0a0A0 } -> [ Kassel ] { color: red; }|3,Berlin,Bonn,Kassel
[ Bonn ] -> [ Berlin ]\n -> [ Kassel ] -> [ Koblenz ]|4,Berlin,Bonn,Kassel,Koblenz
[ Bonn ] -> [ Berlin ] -> [ Kassel ]\n -> [ Koblenz ]|4,Berlin,Bonn,Kassel,Koblenz
[ Bonn ] -> [ Berlin ] -> [ Kassel ] -> [ Koblenz ]|4,Berlin,Bonn,Kassel,Koblenz
# attributes with ":" in their value
[ Bonn ] { link: http://www.bloodgate.com/Bonn; }|1,Bonn
# edges with label
[ Bonn ] - Auto--> [ Berlin ]|2+1,Auto,Berlin,Bonn
[ Bonn ] - Auto --> [ Berlin ]|2+1,Auto,Berlin,Bonn
# groups
( Group [ Bonn ] - Auto --> [ Berlin ] )|2+1,Auto,Berlin,Bonn
( Group [ Bonn ] --> [ Berlin ] )|2,Berlin,Bonn
# lists
[ Bonn ], [ Berlin ]\n --> [ Hamburg ]|3,Berlin,Bonn,Hamburg
[ Bonn ], [ Berlin ] --> [ Hamburg ]|3,Berlin,Bonn,Hamburg
[ Bonn ], [ Berlin ], [ Ulm ] --> [ Hamburg ]|4,Berlin,Bonn,Hamburg,Ulm
[ Bonn ], [ Berlin ], [ Ulm ] --> [ Hamburg ] [ Trier ] --> [ Ulm ]|5,Berlin,Bonn,Hamburg,Trier,Ulm
( Group [ Bonn ], [ Berlin ] => [ Leipzig ] ) { color: red; }|3,Berlin,Bonn,Leipzig
[ Bonn ] -> [ Berlin ]\n --> { color: red; } [ Leipzig ]|3,Berlin,Bonn,Leipzig
[ Bonn ] --> { label: test; } [ Berlin ]|2+1,test,Berlin,Bonn
[ Bonn ] --> { label: test; } [ Berlin ] { color: blue; }|2+1,test,Berlin,Bonn
[ Bonn ] --> { label: test; } [ Berlin ] { color: blue; }|2+1,test,Berlin,Bonn
[ Bonn ] --> { label: test; } [ Berlin ] { color: blue; } --> { label: test2; } [ Leipzig ]|3+2,test2,test,Berlin,Bonn,Leipzig

