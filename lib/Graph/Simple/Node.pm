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
# If you change this, change it also in Simple.pm!
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

  $self->{name} = 'Node #' . $self->{id};
  # attributes
  $self->{att} = { };
  $self->{class} = 'node';		# default class

  # XXX TODO check arguments
  foreach my $k (keys %$args)
    {
    $self->{$k} = $args->{$k};
    }
  
  $self->{error} = '';

  # w can only be computed once we know our graph and our border style, so postpone it
  $self->{h} = 1 + 2 if !defined $self->{h};
  
  $self->{x} = 0;
  $self->{y} = 0;
  
  $self->{out} = {};
  $self->{in} = {};
  
  $self->{contains} = undef;
 
  $self;
  }

sub _correct_w
  {
  my $self = shift;

  if (!defined $self->{w})
    {
    my $border = $self->attribute('border') || 'none';
    if ($border eq 'none')
      {
      $self->{w} = length($self->{name}) + 2;
      }
    else
      {
      $self->{w} = length($self->{name}) + 4;
      }
    }
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

  my $border = $self->attribute('border') || 'none';
  if ($border eq 'none')
    {
    # 'Sample'
    for my $l (split /\n/, $self->{name})
      {
      $txt .= "$l\n";
      }
    }
  elsif ($border =~ 'solid')
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

sub attributes_as_txt
  {
  my $self = shift;

  my $att = '';
  my $class = $self->class();
  my $a = $self->{att};
  for my $atr (sort keys %$a)
    {
    # attribute not defined
    next if !defined $a->{$atr};

    # attribute defined, but same as default
    if (defined $self->{graph})
      {
      my $DEF = $self->{graph}->attribute ($class, $atr);
      next if defined $DEF && $a->{$atr} eq $DEF;
      }

    my $val = $a->{$atr};
    # encode critical characters
    $val =~ s/([:;\x00-\x20])/sprintf("%%%02x",ord($1))/eg;

    $att .= "$atr: $val; ";
    }

  # include our subclass as attribute
  $att .= "class: $1; " if $class =~ /\.(\w+)/;
  
  # generate attribute text if nec. 
  $att = ' { ' . $att . '}' if $att ne '';

  $att;
  }

sub as_txt_node
  {
  my $self = shift;
  
  my $name = $self->{name};

  # quote special chars in name
  $name =~ s/([\[\]\(\)\{\}\#])/\\$1/g;

  '[ ' .  $name . ' ]';
  }

sub as_txt
  {
  my $self = shift;

  my $name = $self->{name};

  # quote special chars in name
  $name =~ s/([\[\]\(\)\{\}\#])/\\$1/g;

  '[ ' .  $name . ' ]' . $self->attributes_as_txt();
  }

sub as_html
  {
  my ($self, $tag, $id) = @_;

  $tag = 'td' unless defined $tag && $tag ne '';
  $id = '' unless defined $id;

  # return yourself as HTML

  my $class = $self->class();
  my $c = $class; $c =~ s/\./-/g;	# node.city => node-city
  my $html = "<$tag class='$c$id'";
  
  my $style = '';
  my $a = $self->{att};
  for my $atr (sort keys %$a)
    {
    # attribute not defined
    next if !defined $a->{$atr};
    
    # skip these:
    next if $atr =~
	/^(linkbase|link|autolink|autotitle|title)\z/;

    # attribute defined, but same as default (or node not in a graph)
    if (!defined $self->{graph})
      {
      print STDERR "Node $self->{name} is not associated with a graph!\n";
      }
    next unless defined $self->{graph};
    
    my $DEF = $self->{graph}->attribute ($class, $atr);
    next if defined $DEF && $a->{$atr} eq $DEF;

    $style .= "$atr: $a->{$atr}; ";
    }
  $style =~ s/;\s$//;				# remove '; ' at end
  $html .= " style=\"$style\"" if $style;

  my $title = $self->attribute('title');
  my $autotitle = $self->attribute('autotitle');
  if (!defined $title && defined $autotitle && $autotitle eq 'name')
    {
    $title = $self->{name};
    }
  $title = '' unless defined $title;

  if ($title ne '')
    {
    $title =~ s/"/''/g;				# remove quotation mark
    $html .= " title=\"$title\"";		# cell with mouse-over title
    }
  my $name = $self->{name};

  $name =~ s/&/&amp;/g;				# quote &
  $name =~ s/>/&gt;/g;				# quote >
  $name =~ s/</&lt;/g;				# quote <

  $name =~ s/\n/<br>/g;				# |\n|\nv => |<br>|<br>v
  $name =~ s/^\s*<br>//;			# remove empty leading line

  my $link = $self->attribute('link');
  my $autolink = $self->attribute('autolink');
  if (!defined $link && defined $autolink && $autolink eq 'name')
    {
    $link = $self->{name};
    }
  $link = '' unless defined $link;

  # only if link is relative, prepend base
  if ($link ne '' && $link !~ /^\w+:\/\//)
    {
    my $base = $self->attribute('linkbase');
    $link = $base . $link if defined $base;
    }

  if ($link ne '')
    {
    # decode %XX entities
    $link =~ s/%([a-fA-F0-9][a-fA-F0-9])/sprintf("%c",hex($1))/eg;
    $html .= "> <a href='$link'>$name</a> </$tag>\n";
    }
  else
    {
    $html .= "> $name </$tag>\n";
    }
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

  my $g = $self->{graph}->{graph};
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

  my $g = $self->{graph}->{graph};
  return () unless defined $g;

  my @p = $g->predecessors( $self->{name} );

  my @N;
  foreach my $pr (@p)
    {
    push @N, $g->get_vertex_attribute( $pr, OBJ );
    }
  @N;
  }

sub class
  {
  my $self = shift;

  $self->{class} || 'node';
  }

sub sub_class
  {
  my $self = shift;

  if (defined $_[0])
    {
    $self->{class} =~ s/\..*//;		# nix subclass
    $self->{class} .= '.' . $_[0];	# append new one
    }
  }

sub attribute
  {
  my ($self, $atr) = @_;

  return $self->{att}->{$atr} if exists $self->{att}->{$atr};

  # if we do not belong to a graph, we cannot inherit attributes
  return unless defined $self->{graph};

  my $class = $self->class();
  
  my $att = $self->{graph}->attribute ($self->{class} || 'node', $atr);

  # If our parent class (like "node" for "node.city") doesnt have the
  # attribute, see if we can inherit it from "graph":
  if (!defined $att)
    {
    $att = $self->{graph}->attribute ('graph', $atr);
    }
  $att;
  }

sub set_attribute
  {
  my ($self, $atr, $v) = @_;
  
  my $val = $v;
  # remove quotation marks
  $val =~ s/^["']//;
  $val =~ s/["']\z//;

  # decode %XX entities
  $val =~ s/%([a-fA-F0-9][a-fA-F0-9])/sprintf("%c",hex($1))/eg;

  if ($atr eq 'class')
    {
    $self->sub_class($val);
    return $self;
    }
  $self->{att}->{$atr} = $val;
  $self;
  }

sub set_attributes
  {
  my ($self, $atr) = @_;
  
  foreach my $n (keys %$atr)
    {
    $n eq 'class' ? $self->sub_class($atr->{$n}) : $self->set_attribute($n, $atr->{$n});
    }
  $self;
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

	my $html = $node->as_html($tag, $id);

Return the node in HTML. The C<$tag> is the optional name of the HTML
tag to surround the node name with. C<$id> is an optional ID that is
tagged onto the classname for the CSS.

Example:

	print $node->as_html('span');

Would print something like:

	<span class="node"> Bonn </span>

While:

	print $node->as_html('td');

Would print something like:

	<td class="node"> Bonn </td>

The following:

	print $node->as_html('span', '12');

Would print something like:

	<span class="node12"> Bonn </span>

=head2 attribute()

	$node->attribute('border');

Returns the respective attribute of the node or undef if it
was not set. If there is a default attribute for all nodes
of the specific class the node is in, then this will be returned.

=head2 set_attribute()

	$node->set_attribute('border', 'none');

Sets the specified attribute of this (and only this!) node to the
specified value.

=head2 set_attributes()

	$node->set_attributes( $hash );

Sets all attributes specified in C<$hash> as key => value pairs in this
(and only this!) node.

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
