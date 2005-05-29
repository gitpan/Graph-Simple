#############################################################################
# (c) by Tels 2004-2005. A cluster of relativ positioned nodes.
# Part of Graph::Simple.
#
#############################################################################

package Graph::Simple::Cluster;

use 5.006001;
use strict;

use vars qw/$VERSION @ISA/;
use Graph::Simple::Node;

@ISA = qw/Graph::Simple::Node/;
$VERSION = '0.01';

{
  # protected vars
  my $id = 0;
  sub new_id { $id++; }
  sub _reset_id { $id = 0; }
}

#############################################################################

sub _init
  {
  # generic init, override in subclasses
  my ($self,$args) = @_;
 
  $self->{id} = new_id();
  $self->{name} = 'Cluster #' . $self->{id};

  # XXX TODO check arguments
  foreach my $k (keys %$args)
    {
    $self->{$k} = $args->{$k};
    }
  
  # list of nodes that belong to that cluster
  $self->{nodes} = {};
  $self->{error} = '';
  $self->{graph} = undef;

  $self;
  }

sub error
  {
  my $self = shift;

  $self->{error} = $_[0] if defined $_[0];
  $self->{error};
  }

#############################################################################
# accessor methods

sub nodes
  {
  my $self = shift;

  ( values %{$self->{nodes}} );
  }

#############################################################################
# node handling

sub add_node
  {
  my ($self,$n) = @_;
 
  if (ref($n) !~ /Graph::Simple::Node/)
    {
    require Carp;
    Carp::croak("Cannot add non-node $n to cluster");
    }
  $self->{nodes}->{ $n->{name} } = $n;

  $self;
  }

sub add_nodes
  {
  my $self = shift;

  foreach my $n (@_)
    {
    if (ref($n) !~ /Graph::Simple::Node/)
      {
      require Carp;
      Carp::croak("Cannot add non-node $n to cluster");
      }
    $self->{nodes}->{ $n->{name} } = $n;
    }
  $self;
  }

sub center_node
  {
  # set the passed node as the center of the cluster
  my ($self) = shift;

  if ($_[0])
    {
    # add the node to ourself (in case it wasn't already)
    my $node = shift;
    $self->add_node($node) unless exists $self->{nodes}->{ $node->{name} };
    $self->{center_node} = $node; 
    }
  $self->{center_node}; 
  }

1;
__END__

=head1 NAME

Graph::Simple::Cluster - Nodes positioned relatively to each other

=head1 SYNOPSIS

        use Graph::Simple::Cluster;

	my $bonn = Graph::Simple::Node->new(
		name => 'Bonn',
		border => 'solid 1px black',
		pos => '0,0',
	);
	my $berlin = Graph::Simple::Node->new(
		name => 'Berlin',
		pos => '1,0',
	);
	my $cities = Graph::Simple::Cluster->new();

	$cities->add_node ($bonn);
	# $bonn will be ONCE in the group
	$cities->add_nodes ($bonn, $berlin);
	$cities->set_center($bonn);

=head1 DESCRIPTION

A C<Graph::Simple::Cluster> represents a group of nodes that are all
positioned relatively to each other.

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

Copyright (C) 2004 - 2005 by Tels L<http://bloodgate.com>

See the LICENSE file for more details.

=cut
