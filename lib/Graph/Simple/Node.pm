#############################################################################
# (c) by Tels 2004. Part of Graph::Simple
#
#############################################################################

package Graph::Simple::Node;

use 5.006001;
use strict;
use warnings;

use vars qw/$VERSION/;

$VERSION = '0.03';

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
  
  # +--------+
  # | Sample |
  # +--------+

  $self->{id} = new_id();		# get a new, unique ID

  $self->{border} = '1px solid black';
  $self->{name} = 'Node #' . $self->{id};

  # XXX TODO check arguments
  foreach my $k (keys %$args)
    {
    $self->{$k} = $args->{$k};
    }
  
  $self->{error} = '';

  if (!defined $self->{w})
    {
    if ($self->{border} eq 'none')
      {
      $self->{w} = length($self->{name}) + 2;
      }
    else
      {
      $self->{w} = length($self->{name}) + 4;
      }
    }
  $self->{h} = 1 + 2 if !defined $self->{h};
  
  $self->{x} = 0;
  $self->{y} = 0;
  
  $self->{out} = {};
  $self->{in} = {};
  
  $self->{contains} = undef;
  
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
  elsif ($self->{border} =~ 'solid')
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
  # XXX TODO: handle "dotted", "dashed"
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

  '[ ' .  $self->{name} . ' ]';
  }

my $DEF = {
    'text-align' => 'center',
    'background' => 'white',
    'border' => '1px solid black',
  };

sub as_html
  {
  my ($self, $tag) = @_;

  $tag = 'td' unless defined $tag && $tag ne '';

  # return yourself as HTML

  my $class = $self->{class} || 'node';
  my $html = "<$tag class='$class'";
  
  my $style = '';
  for my $atr (qw/
    border background color margin padding font-style font-weight text-align
   /)
    {
    # attribute not defined
    next if !defined $self->{$atr};
    # attribute defined, but same as default
    next if defined $DEF->{$atr} && $self->{$atr} eq $DEF->{$atr};

    my $a = $self->{$atr};
    $a = $DEF->{$atr} unless defined $a;
    $style .= "$atr: $a; ";
    }
  $style =~ s/\s$//;				# remove last ' '
  $html .= " style=\"$style\"" if $style;

  my $name = $self->{name};

  $name =~ s/&/&amp;/g;				# quote &
  $name =~ s/>/&gt;/g;				# quote >
  $name =~ s/</&lt;/g;				# quote <

  $name =~ s/\n/<br>/g;				# |\n|\nv => |<br>|<br>v
  $name =~ s/^\s*<br>//;			# remove empty leading line
  $html .= "> $name </$tag>\n";
  $html;
  }

#############################################################################
# accessor methods

sub x
  {
  my $self = shift;

  $self->{x};
  }

sub contains
  {
  my $self = shift;

  $self->{contains};
  }

sub name
  {
  my $self = shift;

  $self->{name};
  }

sub y
  {
  my $self = shift;

  $self->{y};
  }

sub pos
  {
  my $self = shift;

  ($self->{x}, $self->{y});
  }

sub width
  {
  my $self = shift;

  $self->{w};
  }

sub height
  {
  my $self = shift;

  $self->{h};
  }

sub successors
  {
  # return all nodes (as objects) we are linked to
  my $self = shift;

  my $g = $self->{graph};
  return () unless defined $g;

  my @s = $g->successors( $self->{name} );

  my @N;
  foreach my $su (@s)
    {
    push @N, $g->get_vertex_attribute( $su, OBJ );
    }
  @N;
  }

sub predecessors
  {
  # return all nodes (as objects) that link to us
  my $self = shift;

  my $g = $self->{graph};
  return () unless defined $g;

  my @p = $g->predecessors( $self->{name} );

  my @N;
  foreach my $pr (@p)
    {
    push @N, $g->get_vertex_attribute( $pr, OBJ );
    }
  @N;
  }

1;
__END__

=head1 NAME

Graph::Simple::Node - Represents a node (a box) in a simple graph

=head1 SYNOPSIS

        use Graph::Simple::Node;

	my $bonn = Graph::Simple::Node->new(
		name => 'Bonn',
		border => 'solid 1px black',
	);
	my $berlin = Graph::Simple::Node->new(
		name => 'Berlin',
	)

=head1 DESCRIPTION

A C<Graph::Simple::Node> represents a node in a simple graph. Each
node has contents (a text, an image or another graph), and dimension plus
an origin. The origin is typically determined by a graph layouter module
like L<Graph::Simple>.

=head1 METHODS

        my $node = Graph::Simple::Group->new( $options );

Create a new node. C<$options> are the possible options:

	name		Name of the node
	border		Border style and color

=head2 error()

	$last_error = $node->error();

	$node->error($error);			# set new messags
	$node->error('');			# clear error

Returns the last error message, or '' for no error.

=head2 as_ascii()

	my $ascii = $node->as_ascii();

Return the node as a little box drawn in ASCII art as a string.

=head2 as_txt()

	my $txt = $node->as_txt();

Return the node in simple txt format.

=head2 as_html()

	my $html = $node->as_html($tag);

Return the node in HTML. The C<$tag> is the optional name of the HTML
tag to surround the node name with.

Example:

	print $node->as_html('span');

Would print something like:

	<span style="border: 1px solid black"> Bonn </span>

While:

	print $node->as_html('td');

Would print something like:

	<td style="border: 1px solid black"> Bonn </td>

=head2 name()

	my $name = $node->name();

Return the name of the node.

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