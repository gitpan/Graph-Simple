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

  $self->{border} = 'solid';
  $self->{name} = 'Sample';

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

  '[ ' .  $self->{name} . ' ]';
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
  # return all nodes we are linked to
  my $self = shift;

  my $g = $self->{graph};
  return () unless defined $g;

  my @s = $g->successors( $self->{name} );

  my @N;
  foreach my $su (@s)
    {
    push @N, $g->get_attribute('obj', $su);
    }
  @N;
  }

sub predecessors
  {
  my $self = shift;

  my $g = $self->{graph};
  return () unless defined $g;

  my @p = $g->predecessors( $self->{name} );

  my @N;
  foreach my $pr (@p)
    {
    push @N, $g->get_attribute('obj', $pr);
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

=head2 error()

	$last_error = $node->error();

	$cvt->error($error);			# set new messags
	$cvt->error('');			# clear error

Returns the last error message, or '' for no error.

=head2 as_ascii()

	my $ascii = $node->as_ascii();

Return the node as a little box drawn in ASCII art as a string.

=head2 name()

	my $name = $node->name();

Return the unique name of the node.

=head2 contents()

=head2 width()

=head2 height()

=head2 pos()

=head2 x()

=head2 y()

=head2 predecessors()

=head2 successors()

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
