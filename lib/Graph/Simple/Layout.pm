#############################################################################
# Layout directed graphs on a flat plane. Part of Graph::Simple.
#
# (c) by Tels 2004-2005.
#############################################################################

package Graph::Simple::Layout;

use vars qw/$VERSION/;

$VERSION = '0.05';

#############################################################################
#############################################################################

package Graph::Simple;

use strict;
use Graph::Simple::Node::Cell;
use Graph::Simple::Edge::Cell qw/
  EDGE_SHORT_E
  EDGE_SHORT_W
  EDGE_SHORT_N
  EDGE_SHORT_S

  EDGE_START_E
  EDGE_START_W
  EDGE_START_N
  EDGE_START_S

  EDGE_END_E
  EDGE_END_W
  EDGE_END_N
  EDGE_END_S

  EDGE_HOR
  EDGE_VER
  EDGE_CROSS
 /;

#############################################################################
# layout the graph

sub layout
  {
  my $self = shift;

  # XXX todo: find a better layout for all the nodes

  ###########################################################################
  # prepare our stack of things we need to do before we are finished

  my @V = $self->sorted_nodes();

  my @todo;				# actions still to do
  # for all nodes, reset their pos and push them on the todo stack
  foreach my $n (@V)
    {
    $n->{x} = undef;			# mark as not placed yet
    $n->{y} = undef;
    push @todo, $n;			# node needs to be placed
    foreach my $o ($n->successors())
      {
      print STDERR "push $n->{name} => $o->{name}\n" if $self->{debug};
      push @todo, [ $n, $o ];		# paths to all targets need to be found
      }
    }

  ###########################################################################
  # prepare main backtracking-loop

  my $score = 0;			# overall score
  $self->{cells} = {};			# cell array (0..x,0..y)
  my $cells = $self->{cells};

  print STDERR "# Start\n" if $self->{debug};

  my @done = ();			# stack with already done actions
  my $step = 0;
  my $tries = 4;

  TRY:
  while (@todo > 0)			# all actions on stack done?
    {
    $step ++;
#    sleep(1) if $self->{debug};
    
    print STDERR "\n# Step $step: Score is $score\n" if $self->{debug};

    # pop one action
    my $action = shift @todo;

    push @done, $action;

    my ($src, $dst, $mod);

    print STDERR "# Step $step: Action $action\n" if $self->{debug};

    if (ref($action) ne 'ARRAY')
      {
      print STDERR "# step $step: got place '$action->{name}'\n" if $self->{debug};
      # is node to be placed
      if (!defined $action->{x})
        {
        $mod = $self->_place_node( $cells, $action );
        }
      else
        {
        $mod = 0;				# already placed
        }
      }
    else
      {
      # find a path to the target node

      ($src,$dst) = @$action;

      print STDERR "# step $step: got trace '$src->{name}' => '$dst->{name}'\n" if $self->{debug};

      # if target node not yet placed
      if (!defined $dst->{x})
        {
        print STDERR "# Step $step: $dst->{name} not yet placed\n"
         if $self->{debug};

        # put current action back
        unshift @todo, $action;
        # insert action to place target beforehand
        unshift @todo, $dst;
        next TRY;
        }

      # find path (mod is score modifier, or undef if no path exists)
      $mod = $self->_trace_path( $src, $dst );
      }

    if (!defined $mod)
      {
      # rewind stack
      if (ref($action) ne 'ARRAY')
        { 
        print STDERR "# Step $step: Rewind stack for $action->{name}\n" if $self->{debug};

        # free cell area (XXX TODO: nodes that occupy more than one area)
        delete $cells->{"$action->{x},$action->{y}"};
        # mark node as tobeplaced
        $action->{x} = undef;
        $action->{y} = undef;
        }
      else
        {
        print STDERR "# Step $step: Rewind stack for path from $src->{name} to $dst->{name}\n" if $self->{debug};
    
        # XXX TODO: free cell area

        print STDERR "# Step $step: Rewound\n" if $self->{debug};
          
        # if we couldn't find a path, we need to rewind one more action (just
	# redoing the path would would fail again)

        unshift @todo, $action;
        unshift @todo, pop @done;
        if (ref($todo[0]) && ref($todo[0]) ne 'ARRAY')
          {
          print STDERR ref($todo[0]),"\n";;
          my $action = $todo[0];
          delete $cells->{"$action->{x},$action->{y}"};
          # mark node as tobeplaced
          $action->{x} = undef;
          $action->{y} = undef;
          }
  	$tries--;
	last TRY if $tries == 0;
        next TRY;
        }
      unshift @todo, $action;
      next TRY;
      }

    $score += $mod;
    print STDERR "# Step $step: Score is $score\n" if $self->{debug};
    }

  $self->{score} = $score;			# overall score
 
  $self->error( 'Layouter failed to place and/or connect all nodes' ) if $tries == 0;

  # all things on the stack were done, or we encountered an error

  # fill in group info and return
  $self->_fill_group_cells($cells);
  }

sub _place_node
  {
  my ($self, $cells, $node) = @_;

  print STDERR "# Finding place for $node->{name}\n" if $self->{debug};

  # try to place node at upper left corner
  my $x = 0;
  my $y = 0;
  if (!exists $cells->{"$x,$y"})
    {
    $cells->{"$x,$y"} = $node;
    $node->{x} = $x;
    $node->{y} = $y;
    return 0;
    }
        
  # try to place node near the predecessor
  my @pre = $node->predecessors();
  if (@pre == 1 && defined $pre[0]->{x})
    {
    my @tries = ( 
	$pre[0]->{x} + 2, $pre[0]->{y},		# right
	$pre[0]->{x}, $pre[0]->{y} + 2,		# down
	$pre[0]->{x} - 2, $pre[0]->{y},		# left
	$pre[0]->{x}, $pre[0]->{y} - 2,		# up
      );

    print STDERR "# Trying simple placement of $node->{name}\n" if $self->{debug};
    while (@tries > 0)
      {
      my $x = shift @tries;
      my $y = shift @tries;

      if (!exists $cells->{"$x,$y"})
        {
        print STDERR "# Placing $node->{name} at $x,$y\n" if $self->{debug};
        $cells->{"$x,$y"} = $node;
        $node->{x} = $x;
        $node->{y} = $y;
        return 0;
        }
      }

    # all simple possibilities exhausted
    } 

  # if no predecessors/incoming edges, try to place in column 0
  if (@pre == 0)
    {
    my $y = 0;
    while (exists $cells->{"0," . $y})
      {
      $y += 2;
      }
    $y += 1 if exists $cells->{"0," . ($y-1)};	# leave one space
    print STDERR "# Placing $node->{name} at $x,$y\n" if $self->{debug};
    $cells->{"$x,$y"} = $node;
    $node->{x} = $x;
    $node->{y} = $y;
    return 0;
    }

  # XXX TODO: 100 => 100000 and limit tries
  # XXX TODO: try to place the node near the one it is linked to
  while (!defined $node->{x})
    {
    my $x = int(rand(100));
    my $y = int(rand(100));
    if (!exists $cells->{"$x,$y"})
      {
      $cells->{"$x,$y"} = $node;
      $node->{x} = $x;
      $node->{y} = $y;
      }
    }
  0;					# success 
  }

sub _trace_path
  {
  my ($self, $src, $dst) = @_;

  my $cells = $self->{cells};

  print STDERR "# Finding path from $src->{name} to $dst->{name}\n" if $self->{debug};
  # find a free way from $src to $dst (both need to be placed)
  my $mod = 0;

#  print STDERR "src: $src->{x}, $src->{y} dst: $dst->{x}, $dst->{y}\n";

  my ($dx,$dy,@coords) = $self->_trace_straight_path ($src, $dst);

  if (@coords != 0)
    {

    # found a path

    my $mod = 1;			# for straight paths: score +1
    $mod++ if @coords == 1;		# for short paths: score +1

    if ($src->{x} == $dst->{x}-2 && $src->{y} == $dst->{y})
      {
      $mod += 2;			# +2 if right
      }
   elsif ($src->{x} == $dst->{x} && $src->{y} == $dst->{y} - 2)
      {
      $mod += 1;			# +1 if down
      }

   my $x = $src->{x} + $dx;
   my $y = $src->{y} + $dy;

   my $edge = $self->edge($src,$dst);

   # now for each coord, allocate the cell
   if (@coords == 1)
     {
     $self->_create_edge( $edge, $src, $dst, $dx, $dy, $x, $y);
     }
   else
     {
     # Longer path with at least two elements. So create all cells like
     # "start" cell, "end" cell and intermidiate pieces
     
     while (@coords > 1)				# leave end piece
       {
       my ($x,$y,$type) = split /,/, shift @coords;
       $self->_put_path($edge,$x,$y,$type);
       }

     my ($x,$y,$type) = split /,/, shift @coords;
     # final edge element (end piece)
     $self->_create_edge( $edge, $src, $dst, $dx, $dy, $x, $y, 'endpoint');
     }
    }
  else
    {
    # XXX TODO
    print STDERR "# Unable to find path from $src->{name} ($src->{x},$src->{y}) to $dst->{name} ($dst->{x},$dst->{y})\n";
    sleep(1);
    return undef;
    }
  $mod;
  }

sub _create_edge
  {
  my ($self,$edge, $src, $dst, $dx,$dy, $x,$y, $type) = @_;

  my $s = $self->edge($src,$dst);

  if (!defined $type)
    {
    # short path
    $type = EDGE_SHORT_E if ($dx ==  1 && $dy ==  0);
    $type = EDGE_SHORT_S if ($dx ==  0 && $dy ==  1);
    $type = EDGE_SHORT_W if ($dx == -1 && $dy ==  0);
    $type = EDGE_SHORT_N if ($dx ==  0 && $dy == -1);
    }
  elsif ($type eq 'endpoint')
    {
    # endpoint
    $type = EDGE_END_E if ($dx ==  1 && $dy ==  0);
    $type = EDGE_END_S if ($dx ==  0 && $dy ==  1);
    $type = EDGE_END_W if ($dx == -1 && $dy ==  0);
    $type = EDGE_END_N if ($dx ==  0 && $dy == -1);
    }
  elsif ($type eq 'startpoint')
    {
    # startingpoint
    $type = EDGE_START_E if ($dx ==  1 && $dy ==  0);
    $type = EDGE_START_S if ($dx ==  0 && $dy ==  1);
    $type = EDGE_START_W if ($dx == -1 && $dy ==  0);
    $type = EDGE_START_N if ($dx ==  0 && $dy == -1);
    }

  print STDERR "# Found simple path from $src->{name} to $dst->{name}\n" if $self->{debug};
  
  $self->_put_path($edge,$x,$y,$type);
  }

sub _put_path
  {
  my ($self,$edge,$x,$y,$type) = @_;

  my $path = Graph::Simple::Edge::Cell->new( type => $type, edge => $edge, x => $x, y => $y );
  $path->{graph} = $self;		# register path elements with ourself
  $self->{cells}->{"$x,$y"} = $path;	# store in cells
  }

sub _trace_straight_path
  {
  my ($self, $src, $dst) = @_;

  # check that a straigh path from point A to B exists
  my ($x0, $y0) = ($src->{x}, $src->{y});
  my ($x1, $y1) = ($dst->{x}, $dst->{y});

  my $dx = ($x1 - $x0) <=> 0;
  my $dy = ($y1 - $y0) <=> 0;
    
  # if ($dx == 0 && $dy == 0) then we have only a short edge

  my $cells = $self->{cells};
  my @coords;
  my ($x,$y) = ($x0+$dx,$y0+$dy);			# starting pos

  if ($dx != 0 && $dy != 0)
    {
    # straight path not possible, since x0 != x1 AND y0 != y1
    # XXX TODO: try to trace a path with a bend

    #           "  |"                        "|   "
    # try first "--+" (aka hor => ver), then "+---" (aka ver => hor)
    my $done = 0;

    # try hor => ver
    my $type = EDGE_HOR;

    while ($x != $x1)
      {
      $done++, last if exists $cells->{"$x,$y"};	# cell already full

      push @coords, "$x,$y," . $type;		# good one, is free
      $x += $dx;				# next field
#     print STDERR "at $x $y ($x0,$y0 => $x1,$y1) $dx $dy\n"; sleep(1);
      };

    if ($done == 0 && @coords > 0)
      {
      ($x,$y,$type) = split/,/, pop @coords;	# remove last step
      # XXX TODO: generate proper bend
      $type = EDGE_CROSS;
      push @coords, "$x,$y," . $type;		# put in bend

      while ($y != $y1)
        {
        $done++, last if exists $cells->{"$x,$y"};	# cell already full

        push @coords, "$x,$y," . $type;		# good one, is free
        $y += $dy;				# next field
#         print STDERR "at $x $y $dx $dy\n"; sleep(1);
        }
      }

    $done = 1;
    if ($done != 0)
      {
      # try ver => hor
      }
    return () if $done > 0;			# couldn't find one
    }

  my $type = EDGE_HOR; $type = EDGE_VER if $dx == 0;	# - or |
  do
    {
    # XXX TODO handle here crossing paths
    return () if exists $cells->{"$x,$y"};	# cell already full

    push @coords, "$x,$y," . $type;		# good one, is free
    $x += $dx;					# next field
    $y += $dy;
    } while (($x != $x1) || ($y != $y1));
  ($dx,$dy,@coords);				# return all fields of path
  }

sub _remove_path
  {
  # Take an edge, and remove all the cells it covers from the cells area
  my ($self, $edge) = @_;

  my $cells = $self->{cells};
  my $covered = $edge->cells();

  for my $key (keys %$covered)
    {
    # XXX TODO: handle crossed edges here differently (from CROSS => HOR
    # or VER)
    # free in our cells area
    delete $cells->{$key};
    }
  $edge->clear_cells();
  }

#############################################################################

sub _fill_group_cells
  {
  # after doing a layout(), we need to add the group to each cell based on
  # what group the nearest node is in.
  my ($self, $cells_layout) = @_;

  # if layout not done yet, do so
  $self->layout() unless defined $self->{score};

  # We need to insert "filler" cells around each node/edge/cell. If we do not
  # have groups, this will ensure that nodes in two consecutive rows do not
  # stick together. (We could achive the same effect with "cellpadding=3" on
  # the table, but the cellpadding area cannot be have a different background
  # color, which leaves ugly holes in colored groups).

  # To "insert" the filler cells, we simple multiply each X and Y by 2, this
  # is O(N) where N is the number of actually existing cells. Otherwise we
  # would have to create the full table-layout, and then insert rows/columns.

  my $cells = {};
  for my $key (keys %$cells_layout)
    {
    my ($x,$y) = split /,/, $key;
    my $cell = $cells_layout->{$key};
    $x *= 2;
    $y *= 2;
    $cell->{x} = $x;
    $cell->{y} = $y;
    $cells->{"$x,$y"} = $cells_layout->{$key};
    # now insert filler cells above and left of this cell
    $x -= 1;
    $cells->{"$x,$y"} = Graph::Simple::Node::Cell->new ( graph => $self );
    $y -= 1;
    $cells->{"$x,$y"} = Graph::Simple::Node::Cell->new ( graph => $self );
    $x += 1;
    $cells->{"$x,$y"} = Graph::Simple::Node::Cell->new ( graph => $self);
    }

  $self->{cells} = $cells;		# override with new cell layout

  # take a shortcut if we do not have groups
  return $self if $self->groups == 0;
  
  # for all nodes, set sourounding cells to group
  for my $key (keys %$cells)
    {
    my $n = $cells->{$key};
    my $xn = $n->{x}; my $yn = $n->{y};
    next unless defined $xn && defined $yn;	# only if node was placed

    next if ref($n) =~ /(Group|Node)::Cell/;

    my $group;

    if (ref($n) =~ /Node/)
      {
      my @groups = $n->groups();

      # XXX TODO: handle nodes with more than one group
      next if @groups != 1;			# no group? or more than one?
      $group = $groups[0];
      }
    elsif (ref($n) =~ /Edge/)
      {
      my $edge = $n;
      $edge = $edge->{edge} if ref($n) =~ /Cell/;

      # find out whether both nodes have the same group
      my $left = $edge->from();
      my $right = $edge->to();
      my @l_g = $left->groups();
      my @r_g = $right->groups();
      if (@l_g == @r_g && @l_g > 0 && $l_g[-1] == $r_g[-1])
        {
        # edge inside group
        $group = $l_g[-1];
        }
      }

    next unless defined $group;

    my $background = $group->attribute( 'background' );

    # XXX TODO: take nodes with more than one cell into account
    for my $x ($xn-1 .. $xn+1)
      {
      for my $y ($yn-1 .. $yn+1)
	{
	my $cell;

	if (!exists $cells->{"$x,$y"})
	  {
	  $cell = Graph::Simple::Group::Cell->new (
	    group => $group, graph => $self,
	    );
	  }
        else
          {
	  $cell = $cells->{"$x,$y"};

	  # convert filler cells to group cells
          if (ref($cell) !~ /(Node\z|Edge)/)
	    {
	    $cell = Graph::Simple::Group::Cell->new (
	      graph => $self, group => $group,
 	      );
            }
	  else
	    {
            if (ref($cell) =~ /Edge/)
	      {
              # add the edge-cell to the group
	      $cell->{groups}->{ $group->{name} } = $group;
	      }
	    }
          }
	$cells->{"$x,$y"} = $cell;
	$cell->{x} = $x;
	$cell->{y} = $y;
	# override the background attribute with the one from the group
        $cell->set_attribute('background', $background ) unless ref($cell) =~ /Node/;
	}
      }
    }
  # for all group cells, set their right type (for border) depending on
  # neighbour cells
  for my $key (keys %$cells)
    {
    my $cell = $cells->{$key};
    $cell->_set_type($cells) if ref($cell) =~ /Group::Cell/;
    }
  }

1;
__END__
=head1 NAME

Graph::Simple::Layout - Layout the graph from Graph::Simple

=head1 SYNOPSIS

	use Graph::Simple;
	
	my $graph = Graph::Simple->new();

	my $bonn = Graph::Simple::Node->new(
		name => 'Bonn',
	);
	my $berlin = Graph::Simple::Node->new(
		name => 'Berlin',
	);

	$graph->add_edge ($bonn, $berlin);

	$graph->layout();

	print $graph->as_ascii( );

	# prints:

	# +------+     +--------+
	# | Bonn | --> | Berlin |
	# +------+     +--------+

=head1 DESCRIPTION

C<Graph::Simple::Layout> contains just the actual layout code for
L<Graph::Simple|Graph::Simple>.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Simple>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms of the GPL. See the LICENSE file for information.

=head1 AUTHOR

Copyright (C) 2004 - 2005 by Tels L<http://bloodgate.com>

=cut
