#############################################################################
# (c) by Tels 2004. Part of Graph::Simple
#
#############################################################################

package Graph::Simple::Edge;

use 5.006001;
use strict;
use warnings;

use vars qw/$VERSION/;

$VERSION = '0.01';

#############################################################################

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

  $self->{style} = '-->';
  $self->{name} = '';

  # XXX TODO check arguments
  foreach my $k (keys %$args)
    {
    $self->{$k} = $args->{$k};
    }
  
  $self->{error} = '';

  $self;
  }

sub as_ascii
  {
  my ($self) = @_;

  $self->{style};
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

  ' ' . $self->{style} . ' ';
  }

#############################################################################
# accessor methods

sub name
  {
  my $self = shift;

  $self->{name};
  }

sub style
  {
  my $self = shift;

  $self->{style};
  }

1;
__END__

=head1 NAME

Graph::Simple::Edge - An edge (a path from one node to another)

=head1 SYNOPSIS

        use Graph::Simple;

	my $ssl = Graph::Simple::Edge->new(
		name => 'encrypted connection',
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

	$graph->add_edge($src, $dst, $edge);

	print $graph->as_ascii();

=head1 DESCRIPTION

A C<Graph::Simple::Edge> represents an edge between two nodes in a
simple graph.

Each edge has a direction (from source to destination, or back and forth),
plus a style (line width and style), colors etc. It can also have a name,
e.g. a text associated with it.

=head1 METHODS

=head2 error()

	$last_error = $edge->error();

	$cvt->error($error);			# set new messags
	$cvt->error('');			# clear error

Returns the last error message, or '' for no error.

=head2 as_ascii()

	my $ascii = $edge->as_ascii();

Returns the edge as a little ascii representation.

=head2 name()

=head2 style()

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Graph::Simple>.

=head1 AUTHOR

Tels L<http://bloodgate.com>

=head1 LICENSE

Copyright (C) 2004 by Tels

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL. See the LICENSE file for more details.

=cut
