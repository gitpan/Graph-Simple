#############################################################################
# Parse text definition into a Graph::Simple object
#
# (c) by Tels 2004.
#############################################################################

package Graph::Simple::Parser;

use 5.006001;
use strict;
use warnings;
use Graph::Simple;

use vars qw/$VERSION/;

$VERSION = '0.02';

sub new
  {
  my $class = shift;

  my $self = bless {}, $class;

  my $args = $_[0];
  $args = { @_ } if ref($args) ne 'HASH';

  $self->_init($args);
  }

sub _init
  {
  my ($self,$args) = @_;

  $self->{error} = '';
  
  foreach my $k (keys %$args)
    {
#    if ($k !~ /^(|debug)\z/)
#      {
#      $self->error ("Unknown option '$k'");
#      }
    $self->{$k} = $args->{$k};
    }

  $self;
  }

sub from_text
  {
  my ($self,$txt) = @_;

  my $graph = Graph::Simple->new( { debug => $self->{debug} } );

  return $graph if !defined $txt || $txt =~ /^\s*\z/;		# empty text?

  my @lines = split /\n/, $txt;

  my $c = 'Graph::Simple::Node';
  my $e = 'Graph::Simple::Edge';
  my $nr = -1;
  LINE:
  foreach my $line (@lines)
    {
    $nr++;
    # remove comment:
#    $line =~ s/#.*//;

    chomp($line);

    # remove white space at start/end
    $line =~ s/^\s+//;
    $line =~ s/\s+\z//;

#    print STDERR "at line $nr '$line'\n";

    # [ Berlin ]
    if ($line =~ /^\[\s*([^\]]+?)\s*\]\z/)
      {
      my $n1 = $1;
      my $node_a = $graph->node($n1);
      if (!defined $node_a)
        {
        $node_a = $c->new( { name => $n1 } ); 
        $graph->add_node ( $node_a );
        }
      next LINE;
      }

    # [ Berlin ] -> [ Kassel ]
    #                      1              2    3     4           5
    if ($line =~ /^\[\s*([^\]]+?)\s*\]\s*(<?)([=-]+)(>?)\s*\[\s*([^\]]+?)\s*\]/)
      {
      my $n1 = $1; my $n5 = $5;
      my $node_a = $graph->node($n1);
      my $node_b = $graph->node($n5);
      if (!defined $node_a || !defined $node_b)
        {
        $node_a = $c->new( { name => $n1 } ) unless defined $node_a;
        $node_b = $c->new( { name => $n5 } ) unless defined $node_b;
        my $edge = $e->new( { style => '-->' } );
        $graph->add_edge ( $node_a, $node_b, $edge ); 
        }
      next LINE;
      }

    }

  $graph;
  }

sub error
  {
  my $self = shift;

  $self->{error} = $_[0] if defined $_[0];
  $self->{error};
  }

1;
__END__

=head1 NAME

Graph::Simple::Parser - Parse graph from textual description

=head1 SYNOPSIS

        # creating a graph from a textual description
        use Graph::Simple::Parser;
        my $parser = Graph::Simple::Parser->new();

        my $graph = $parser->from_text(
                '[ Bonn ] => [ Berlin ]'.
                '[ Berlin ] => [ Rostock ]'.
        );
        print $graph->as_ascii( );

=head1 DESCRIPTION

C<Graph::Simple::Parser> lets you parse simple textual descriptions
of graphs, and constructs a C<Graph::Simple> object from them.

The resulting object can than be used to layout and output the graph.

=head2 Input

The input consists of text describing the graph.

	[ Bonn ]      --> [ Berlin ]
	[ Frankfurt ] <=> [ Dresden ]
	[ Bonn ]      --> [ Frankfurt ]

See L<Output> for how this will be rendered in ASCII art.

=head2 Output

The output will be a L<Graph::Simple> object, see there for what you
can do with it.

=head1 EXAMPLES

=head1 METHODS

C<Graph::Simple::Parser> supports the following methods:

=head2 new()

	use Graph::Simple::Parser;
	my $parser = Graph::Simple::Parser->new();

Creates a new parser object.

=head2 from_text()

	my $graph = $parser->from_text();

Create a L<Graph::Simple> object. Returns undef for error, you
can find the error with L<error()>.

This method will reset any previous error, and thus the C<$parser> object
can be re-used to parse different texts.

=head2 error()

	my $error = $parser->error();

Returns the last error.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Simple>.

=head1 AUTHOR

Tels L<http://bloodgate.com>

=head1 LICENSE

Copyright (C) 2004 by Tels

This library is free software; you can redistribute it and/or modify
it under the same terms of the GPL. See the LICENSE file for information.

=cut
