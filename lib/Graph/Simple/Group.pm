#############################################################################
# (c) by Tels 2004. A group of nodes. Part of Graph::Simple
#
#############################################################################

package Graph::Simple::Group;

use 5.006001;
use strict;
use warnings;

use vars qw/$VERSION/;

$VERSION = '0.02';

#############################################################################

# Name of attribute under which the pointer to each Node/Edge object is stored
# If you change this, change it also in Simple.pm/Edge.pm!
sub OBJ () { 'obj' };

{
  # protected vars
  my $id = 0;
  sub new_id { $id++; }
}

#############################################################################

sub new
  {
  my $class = shift;

  my $args = $_[0];
  $args = { name => $_[0] } if ref($args) ne 'HASH' && @_ == 1;
  $args = { @_ } if ref($args) ne 'HASH' && @_ > 1;
  
  my $self = bless {}, $class;

  $self->_init($args);
  }

sub _init
  {
  # generic init, override in subclasses
  my ($self,$args) = @_;
  
  $self->{id} = new_id();		# get a new, unique ID

  $self->{border} = 'solid';
  $self->{name} = 'Group #'. $self->{id};

  # XXX TODO check arguments
  foreach my $k (keys %$args)
    {
    $self->{$k} = $args->{$k};
    }
  
  $self->{nodes} = {};
  $self->{error} = '';

  $self;
  }

sub id
  {
  my $self = shift;

  $self->{id};
  }

sub as_ascii
  {
  my ($self) = @_;

  my $txt;

  if ($self->{border} eq 'none')
    {
    # 'Sample'
    for my $l (split /\n/, $self->{name})
      {
      $txt .= "$l\n";
      }
    }
  elsif ($self->{border} eq 'solid')
    {
    # +--------+
    # | Sample |
    # +--------+
    $txt = '+' . '-' x ($self->{w}-2) . "+\n";
    for my $l (split /\n/, $self->{name})
      {
      $txt .= "| $l |\n";
      }
    $txt .= '+' . '-' x ($self->{w}-2) . "+";
    }
  else
    {
    # ..........
    # : Sample :
    # ..........
    $txt = '.' . '.' x ($self->{w}-2) . ".\n";
    for my $l (split /\n/, $self->{name})
      {
      $txt .= ": $l :\n";
      }
    $txt .= '.' . '.' x ($self->{w}-2) . ".";
    }

  $txt;
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

  my $n = $self->{name};
  # quote special chars in name
  $n =~ s/([\[\]\(\)\{\}\#])/\\$1/g;

  my $txt = "( $n\n";
  
  $n = $self->{nodes};
    
  for my $name ( sort keys %$n )
    {
    $n->{$name}->{_p} = 1;				# mark as processed
    $txt .= '  ' . $n->{$name}->as_pure_txt() . "\n";
    }
  $txt .= ")\n";
  }

#############################################################################
# accessor methods

sub name
  {
  my $self = shift;

  $self->{name};
  }

sub nodes
  {
  my $self = shift;

  ( values %{$self->{nodes}} );
  }

sub add_node
  {
  my ($self,$n) = @_;
 
  if (!ref($n) || ref($n) =~ /Graph::Simple::Group/)
    {
    require Carp;
    Carp::croak("Cannot add non-object or group $n as node to group '$self->{name}'");
    }
  $self->{nodes}->{ $n->{name} } = $n;

  $self;
  }

sub add_nodes
  {
  my $self = shift;

  foreach my $n (@_)
    {
    if (!ref($n) || ref($n) =~ /Graph::Simple::Group/)
      {
      require Carp;
      Carp::croak("Cannot add non-object or group $n as node to group '$self->{name}'");
      }
    $self->{nodes}->{ $n->{name} } = $n;
    }
  $self;
  }

1;
__END__

=head1 NAME

Graph::Simple::Group - Represents a group of nodes in a simple graph

=head1 SYNOPSIS

        use Graph::Simple::Group;

	my $bonn = Graph::Simple::Node->new(
		name => 'Bonn',
		border => 'solid 1px black',
	);
	my $berlin = Graph::Simple::Node->new(
		name => 'Berlin',
	);
	my $cities = Graph::Simple::Group->new(
		name => 'Cities',
	);

	$cities->add_nodes ($bonn);
	# $bonn will be ONCE in the group
	$cities->add_nodes ($bonn, $berlin);


=head1 DESCRIPTION

A C<Graph::Simple::Node> represents a node in a simple graph. Each
node has contents (a text, an image or another graph), and dimension plus
an origin. The origin is typically determined by a graph layouter module
like L<Graph::Simple>.

=head1 METHODS

=head2 new()

	my $group = Graph::Simple::Group->new( $options );

Create a new, empty group. C<$options> are the possible options, see
L<Graph::Simple::Node> for a list.

=head2 error()

	$last_error = $group->error();

	$group->error($error);			# set new messags
	$group->error('');			# clear error

Returns the last error message, or '' for no error.

=head2 as_ascii()

	my $ascii = $group->as_ascii();

Return the group as a little box drawn in ASCII art as a string.

=head2 name()

	my $name = $group->name();

Return the name of the group.

=head2 contents()

	my $contents = $node->contents();

For nested nodes, returns the contents of the node.

=head2 width()

	my $width = $node->width();

Returns the width of the node. This is a unitless number.

=head2 height()

	my $height = $node->height();

Returns the height of the node. This is a unitless number.

=head2 pos()

	my ($x,$y) = $node->pos();

Returns the position of the node. Initially, this is undef, and will be
set from C<Graph::Simple::layout>.

=head2 x()

	my $x = $node->x();

Returns the X position of the node. Initially, this is undef, and will be
set from C<Graph::Simple::layout>.

=head2 y()

	my $y = $node->y();

Returns the Y position of the node. Initially, this is undef, and will be
set from C<Graph::Simple::layout>.

=head2 id()

	my $id = $node->id();

Returns the node's unique ID number.

=head2 predecessors()

	my @pre = $node->predecessors();

Returns all nodes (as objects) that link to us.

=head2 successors()

	my @suc = $node->successors();

Returns all nodes (as objects) that we are linking to.

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Graph::Simple>.

=head1 AUTHOR

Tels L<http://bloodgate.com>

=head1 LICENSE

Copyright (C) 2004 - 2005 by Tels

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL. See the LICENSE file for more details.

=cut
