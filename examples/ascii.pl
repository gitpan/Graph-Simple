#!/usr/bin/perl -w

use strict;
use warnings;

BEGIN
  {
  chdir 'examples' if -d 'examples';
  use lib '../lib';
  }

use Graph::Simple;

#############################################################################
my $graph = Graph::Simple->new();

my $node = Graph::Simple::Node->new( name => 'Bonn' );
my $node2 = Graph::Simple::Node->new( name => 'Berlin' );

$graph->add_edge( $node, $node2 );

print $graph->as_ascii(),"\n";

$graph->{debug} = 0;

my $node3 = Graph::Simple::Node->new( name => 'Frankfurt', border => 'dotted' );

$graph->add_edge( $node2, $node3 );

print $graph->as_ascii(),"\n";

my $node4 = Graph::Simple::Node->new( name => 'Dresden' );

$graph->add_edge( $node3, $node4 );

print $graph->as_ascii(),"\n";

my $node5 = Graph::Simple::Node->new( name => 'Potsdam' );

$graph->add_edge( $node2, $node5 );

print $graph->as_ascii(),"\n";

my $node6 = Graph::Simple::Node->new( name => 'Cottbus' );

$graph->add_edge( $node5, $node6 );

print $graph->as_ascii(),"\n";

