#############################################################################
# Layout directed graphs on a flat plane. Part of Graph::Simple.
#
# (c) by Tels 2004-2005.
#############################################################################

package Graph::Simple::Layout;

use vars qw/$VERSION/;

$VERSION = '0.01';

#############################################################################
#############################################################################

package Graph::Simple;

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
  my $tries = 16;

  TRY:
  while (@todo > 0)			# all actions on stack done?
    {
    $step ++;
#    sleep(1) if $self->{debug};
    
    print STDERR "\n# Step $step: Score is $score\n" if $self->{debug};

    # pop one action
    my $action = shift @todo;

    push @done, $action;

    my ($src, $dst, $mod, @coord);

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
        print STDERR "# Step $step: Try to place node to the right\n" if $self->{debug};

        # try to place node to the right
        my $x = $src->{x} + 2;
        my $y = $src->{y};

        if (!exists $cells->{"$x,$y"})
          {
          print STDERR "# Step $step: Placing $dst->{name} at $x,$y\n" if $self->{debug};
          $cells->{"$x,$y"} = $dst;
          $dst->{x} = $x;
          $dst->{y} = $y;
          }
        else
          {
          # try to place node down
          my $x = $src->{x};
          my $y = $src->{y} + 2;

          if (!exists $cells->{"$x,$y"})
            {
            print STDERR "# Step $step: Placing $dst->{name} at $x,$y\n" if $self->{debug};
            $cells->{"$x,$y"} = $dst;
            $dst->{x} = $x;
            $dst->{y} = $y;
            }
          }

        if (!defined $dst->{x})
          {
          # simple placement didn't work, so try generic solition
          print STDERR "# Step $step: Couldn't place $dst->{name} at $x,$y; retrying generic\n"
           if $self->{debug};

          # put current action back
          unshift @todo, $action;
          # insert action to place target beforehand
          unshift @todo, $dst;
          next TRY;
          }
        }

      # find path (mod is score modifier, or undef if no path exists)
      ($mod, @coord) = $self->_trace_path( $cells, $src, $dst );
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
        # free cell area
        for (my $i = 0; $i < @coord; $i += 2)
          {
          delete $cells->{$coord[$i] . ',' . $coord[$i+1]};
          }
        print STDERR "# Step $step: Rewound\n" if $self->{debug};
          
        # if we couldn't find a path, we need to rewind one more action (just
	# redoing the path would would fail again)

#        use Data::Dumper; print STDERR Dumper( \@done );
        unshift @todo, $action;
        unshift @todo, pop @done;
        if (ref($todo->[0]) && ref($todo->[0]) ne 'ARRAY')
          {
          print STDERR ref($todo->[0]),"\n";;
          my $action = $todo->[0];
          delete $cells->{"$action->{x},$action->{y}"};
          # mark node as tobeplaced
          $action->{x} = undef;
          $action->{y} = undef;
          }
#        print STDERR Dumper( \@done );
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

  # all things on the stack were done

  $self;
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
        
  # try to place node to the right of predecessor
  my @pre = $node->predecessors();
  if (@pre == 1)
    {
    my $x = $pre[0]->{x} + 2;
    my $y = $pre[0]->{y};

    if (!exists $cells->{"$x,$y"})
      {
      print STDERR "# Placing $node->{name} at $x,$y\n" if $self->{debug};
      $cells->{"$x,$y"} = $node;
      $node->{x} = $x;
      $node->{y} = $y;
      return 0;
      }
    }

  # XXX TODO: 100 => 100000 and limit tries
  # try to place the node near the one it is linked to
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
  my ($self, $cells, $src, $dst) = @_;

  print STDERR "# Finding path from $src->{name} to $dst->{name}\n" if $self->{debug};
  # find a free way from $src to $dst (both need to be placed)
  my $mod = 0;
  my @coord = ();

#  print STDERR "src: $src->{x}, $src->{y} dst: $dst->{x}, $dst->{y}\n";

  if ($src->{x} == $dst->{x}-2 && $src->{y} == $dst->{y})
    {
#    print STDERR "# Found simple path from $src->{name} right to $dst->{name}\n";
    # simple case
    my $x = $src->{x} + 1; my $y = $src->{y};
    push @coord, $x, $y;
    print STDERR "# Putting --> at cell $x,$y\n" if $self->{debug};

    my $path = $self->_gen_edge_right( $src, $dst);

    $cells->{"$x,$y"} = $path;
    $path->{x} = $x;
    $path->{y} = $y;
    $mod = 5;				# straight +1, right +3, short +1
    }
  elsif ($src->{x} == $dst->{x} && $src->{y} == $dst->{y} - 2)
    {
#    print STDERR "# Found simple path from $src->{name} down to $dst->{name}\n";
    # simple case
    my $x = $src->{x}; my $y = $src->{y} + 1;
    push @coord, $x, $y;
    print STDERR "# Putting v at cell $x,$y\n" if $self->{debug};

    my $path = $self->_gen_edge_down( $src, $dst);

    $cells->{"$x,$y"} = $path;
    $path->{x} = $x;
    $path->{y} = $y;
    $mod = 4;				# straight +1, down +2, short +1
    }
  elsif ($src->{x} == $dst->{x}+2 && $src->{y} == $dst->{y})
    {
#    print STDERR "# Found simple path from $src->{name} down to $dst->{name}\n";
    # simple case
    my $x = $src->{x}; my $y = $src->{y} + 1;
    push @coord, $x, $y;
    print STDERR "# Putting <-- at cell $x,$y\n" if $self->{debug};

    my $path = $self->_gen_edge_left( $src, $dst);

    $cells->{"$x,$y"} = $path;
    $path->{x} = $x;
    $path->{y} = $y;
    $mod = 3;				# straight +1, left +1, short +1
    }
  elsif ($src->{x} == $dst->{x} && $src->{y} == $dst->{y} + 2)
    {
#    print STDERR "# Found simple path from $src->{name} up to $dst->{name}\n";
    # simple case
    my $x = $src->{x}; my $y = $src->{y} - 1;
    push @coord, $x, $y;
    print STDERR "# Putting v at cell $x,$y\n" if $self->{debug};

    my $path = $self->_gen_edge_up( $src, $dst);

    $cells->{"$x,$y"} = $path;
    $path->{x} = $x;
    $path->{y} = $y;
    $mod = 3;				# straight +1, up +1, short +1
    }
  else
    {
    # XXX TODO
    print STDERR "# Unable to find path from $src->{name} ($src->{x},$src->{y}) to $dst->{name} ($dst->{x},$dst->{y})\n";
    sleep(1);
    return undef;
    }
  ($mod,@coord);
  }

sub _trace_straight_path
  {
  my ($self, $src, $dst) = @_;

  # check that a straigh path from point A to B exists
  my ($x0, $y0) = ($src->{x}, $src->{y});
  my ($x1, $y1) = ($dst->{x}, $dst->{y});

  my ($dx,$dy) = (($x1 - $x0), ($y1 - $y0));

  if ($dx != 0 && $dy != 0)
    {
    # straight path not possible, since x0 != x1 AND y0 != y1
    return;
    }

  my ($x,$y) = ($x0,$y);		# starting pos
  my @coords;
  while ($x != $x1 && $y != $y0)
    {
    # XXX TODO handle here crossing paths
    return if exists $cells->{"$x,$y"};	# cell already full

    push @coords, "$x,$y";		# good one, is free
    $x += $dx;				# next field
    $y += $dy;
    }
  @coords;				# return all fields of path
  }

sub _gen_edge_right
  {
  my ($self, $src, $dst) = @_;
 
  my $s = $self->edge($src,$dst);

  Graph::Simple::Node->new(
    name => "\n $s->{style}", border => 'none', class => 'edge', w => 5, 
    );
  }

sub _gen_edge_down
  {
  my ($self, $src, $dst) = @_;
 
  my $s = $self->edge($src,$dst);

  # Downwards we can only do "|" (line), "| " (dashed) or "." (dotted)
  # e.g. no double line

  my $style = '|'; $style = '.' if $s->{style} =~ /\./;
  my $style2 = $style;
  $style2 = ' ' if $s->{style} =~ /- /;

  Graph::Simple::Node->new(
    name => "  $style\n  $style2\n  v",
    border => 'none', class => 'edge', w => 5, h => 3
    );
  }

sub _gen_edge_up
  {
  my ($self, $src, $dst) = @_;
 
  my $s = $self->edge($src,$dst);

  # Upwards we can only do "|" (line), "| " (dashed) or "." (dotted)
  # e.g. no double line

  my $style = '|'; $style = '.' if $s->{style} =~ /\./;
  my $style2 = $style;
  $style2 = ' ' if $s->{style} =~ /- /;

  Graph::Simple::Node->new(
    name => "  ^\n  $style2\n  $style\n",
    border => 'none', class => 'edge', w => 5, h => 3
    );
  }

sub _gen_edge_left
  {
  my ($self, $src, $dst) = @_;
 
  my $s = $self->edge($src,$dst);

  $s = s/>//;
  Graph::Simple::Node->new(
    name => "\n <$s", border => 'none', class => 'edge', w => 5, w => 3,
    );
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
		border => 'solid 1px black',
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

C<Graph::Simple::Layout> contains the actual layout code.

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
