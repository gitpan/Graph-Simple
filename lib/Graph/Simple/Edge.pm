#############################################################################
# (c) by Tels 2004 - 2005. Part of Graph::Simple
#
#############################################################################

package Graph::Simple::Edge;

use 5.006001;
use strict;
use Graph::Simple::Node;

use vars qw/$VERSION @ISA/;

@ISA = qw/Graph::Simple::Node/;		# an edge is a special node

$VERSION = '0.08';

#############################################################################

sub new
  {
  my $class = shift;

  my $args = $_[0];
  $args = { contents => $_[0] } if ref($args) ne 'HASH' && @_ == 1;
  $args = { @_ } if ref($args) ne 'HASH' && @_ > 1;
  
  my $self = bless {}, $class;

  $self->_init($args);
  }

sub _init
  {
  # generic init, override in subclasses
  my ($self,$args) = @_;
  
  # '-->', '<->', '==>', '<==', '..>' etc
  $self->{style} = '--';

  $self->{class} = 'edge';
  $self->{cells} = { };

  # XXX TODO check arguments
  foreach my $k (keys %$args)
    {
    $self->{$k} = $args->{$k};
    }

  $self->{att}->{label} = $self->{name};
  
  $self->{error} = '';

  $self;
  }

sub error
  {
  my $self = shift;

  $self->{error} = $_[0] if defined $_[0];
  $self->{error};
  }

sub as_txt
  {
  my $self = shift;

  # '- Name ' or ''
  my $n = $self->{att}->{label}; $n = '' unless defined $n;

  $n = '- ' . $n . ' ' if $n ne '';

  # ' - Name -->' or ' --> '
  ' ' . $n . $self->{style} . '> ';
  }

#############################################################################
# accessor methods

sub style
  {
  my $self = shift;

  $self->{style};
  }

sub cells
  {
  # return all the cells this edge currently occupies
  my $self = shift;

  $self->{cells};
  }

sub clear_cells
  { 
  # remove all belonging cells
  my $self = shift;

  $self->{cells} = {};

  $self;
  }

sub add_cell
  {
  # add a cell to the list of cells this edge covers
  my ($self,$cell) = @_;
  
  $self->{cells}->{"$cell->{x},$cell->{y}"} = $cell;
  }

sub from
  {
  my $self = shift;

  $self->{from};
  }

sub to
  {
  my $self = shift;

  $self->{to};
  }

1;
__END__

=head1 NAME

Graph::Simple::Edge - An edge (a path from one node to another)

=head1 SYNOPSIS

        use Graph::Simple;

	my $ssl = Graph::Simple::Edge->new(
		label => 'encrypted connection',
		style => '-->',
		color => 'red',
	);

	my $src = Graph::Simple::Node->new(
		name => 'source',
	);

	my $dst = Graph::Simple::Node->new(
		name => 'destination',
	);

	$graph = Graph::Simple->new();

	$graph->add_edge($src, $dst, $ssl);

	print $graph->as_ascii();

=head1 DESCRIPTION

A C<Graph::Simple::Edge> represents an edge between two (or more) nodes in a
simple graph.

Each edge has a direction (from source to destination, or back and forth),
plus a style (line width and style), colors etc. It can also have a label,
e.g. a text associated with it.

Each edge also contains a list of path-elements (also called cells), which
make up the path from source to destination.

=head1 METHODS

=head2 error()

	$last_error = $edge->error();

	$cvt->error($error);			# set new messags
	$cvt->error('');			# clear error

Returns the last error message, or '' for no error.

=head2 as_ascii()

	my $ascii = $edge->as_ascii();

Returns the edge as a little ascii representation.

=head2 label()

	my $label = $edge->label();

Returns the label (also known as 'name') of the edge.

=head2 style()

	my $style = $edge->style();

Returns the style of the edge, like '--', '==', '..', '- '.

=head2 to_nodes()

	my @nodes = $edge->to_nodes();

Return the nodes this edge connects to, as objects.

=head2 from_nodes()

	my @nodes = $edge->from_nodes();

Return the nodes (that connections come from) as objects.

=head2 nodes()

	my @nodes = $edge->nodes();

Return all the nodes connected (in either direction) by this edge
as objects.

=head2 add_cell()

	$edge->add_cell( $cell );

Add a new cell to the edge. C<$cell> should be an
L<Graph::Simple::Path|Graph::Simple::Path> object.

=head2 clear_cells()

	$edge->clear_cells();

Removes all belonging cells.

=head2 cells()

	my $cells = $edge->cells();

Returns a hash containing all the cells this edge currently occupies. Keys
on the hash are of the form of C<$x,$y> e.g. C<5,3> denoting cell at X = 5 and
Y = 3. The values of the hash are the cell objects.

=head1 EXPORT

None by default.

=head1 TODO

=over 2

=item joints

Edges that join another edge.

=back

=head1 SEE ALSO

L<Graph::Simple>.

=head1 AUTHOR

Copyright (C) 2004 - 2005 by Tels L<http://bloodgate.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL. See the LICENSE file for more details.

=cut
