#############################################################################
# Layout directed graphs as 2D boxes on a flat plane
#
# (c) by Tels 2004.
#############################################################################

package Graph::Simple;

use 5.006001;
use strict;
use warnings;
use Graph::Simple::Node;
use Graph::Simple::Edge;
use Graph::Directed;

use vars qw/$VERSION @ISA/;

@ISA = qw/Graph::Directed/;

$VERSION = '0.03';

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
  $self->{debug} = 0;
  
  foreach my $k (keys %$args)
    {
#    if ($k !~ /^(|debug)\z/)
#      {
#      $self->error ("Unknown option '$k'");
#      }
    $self->{$k} = $args->{$k};
    }

  $self->{score} = undef;

  $self;
  }

sub score
  {
  my $self = shift;

  $self->{score};
  }

sub error
  {
  my $self = shift;

  $self->{error} = $_[0] if defined $_[0];
  $self->{error};
  }

#############################################################################
#############################################################################
# as_foo routines

sub as_html
  {
  # convert the graph to HTML+CSS
  my ($self) = shift;

  $self->layout() unless defined $self->{score};

  } 

############################################################################# 

sub as_txt
  {
  # convert the graph to a textual representation
  # does not need a layout() before hand!
  my ($self) = shift;

  my @nodes = $self->nodes();

  my $txt = '';
  foreach my $n (@nodes)
    {
    my @out = $n->successors();
    my $first = $n->as_txt();
    if ((@out == 0) && ($n->predecessors() == 0))
      {
      $txt .= $first . "\n";
      }
    foreach my $other (@out)
      {
      # XXX TODO: honour style of connection
      my $edge = $self->edge( $n, $other );
      $txt .= $first . ' --> ' . $other->as_txt() . "\n";
      }
    }

  $txt;
  } 

############################################################################# 

sub as_ascii
  {
  # convert the graph to pretty ASCII art
  my ($self) = shift;

  $self->layout() unless defined $self->{score};

  # find out for each row and colum how big they are

  # +--------+-----+------+
  # | Berlin | --> | Bonn | 
  # +--------+-----+------+

  # results in:
  #        w,  h,  x,  y
  # 0,0 => 10, 3,  0,  0
  # 1,0 => 7,  3,  10, 0
  # 2,0 => 8,  3,  16, 0

  # Technically, we also need to "compress" away non-existant columns/rows
  # We achive that by rendering simply them with 0 size, so they are invisible

  my $cells = $self->{cells};
  my $rows = {};
  my $cols = {};
  my @V;

  # find all x and y occurances to sort them by row/columns
  for my $k (keys %$cells)
    {
    my ($x,$y) = split/,/, $k;
    my $node = $cells->{$k};

    # get all possible nodes from $cell (isntead of nodes) because
    # this also includes path nodes
    push @V, $node;

    my $w = $node->{w};
    my $h = $node->{h};
    # record maximum size for that col/row
    $rows->{$y} = $h if $h > ($rows->{$y} || 0);
    $cols->{$x} = $w if $w > ($cols->{$x} || 0);
    } 
  # now run through all rows/columns and get their absolute pos by taking all
  # previous ones into account
  my $pos = 0;
  for my $y (sort { $a <=> $b } keys %$rows)
    {
    #print "setting row $y to $pos\n";
    my $s = $rows->{$y};
    $rows->{$y} = $pos;			# first is 0, second is $rows[1] etc
    $pos += $s;
    }
  $pos = 0;
  for my $x (sort { $a <=> $b } keys %$cols)
    {
    #print "setting col $x to $pos\n";
    my $s = $cols->{$x};
    $cols->{$x} = $pos;
    $pos += $s;
    }

  print STDERR "Have ", scalar @V, " nodes\n" if $self->{debug};

  #use Data::Dumper;
  #print "rows: ", Dumper($rows),"\n";
  #print "cols: ", Dumper($cols),"\n";

  # generate a "framebuffer"
  my @fb = ();
  # find out max. dimensions
  my $max_y = 0; my $max_x = 0;
  foreach my $v (@V)
    {

    # X and Y are col/row, so translate them to real pos
    my $x = $v->{x};
    my $y = $v->{y};
    # print "$v->{name} cell $x,$y ";
    $x = $cols->{ $v->{x} };
    $y = $rows->{ $v->{y} };
    # print " => pos $x,$y\n";

    my $m = $y + $v->{h} - 1;
    $max_y = $m if $m > $max_y;
    $m = $x + $v->{w} - 1;
    $max_x = $m if $m > $max_x;
    }

  for my $y (0..$max_y)
    {
    $fb[$y] = ' ' x $max_x;
    }

  foreach my $v (@V)
    {
    # get as ASCII box
    my @lines = split /\n/, $v->as_ascii();
    # get position from cell
    my $x = $cols->{ $v->{x} };
    my $y = $rows->{ $v->{y} };
    # print $v->{name}. " cell $v->{x},$v->{y} has " . scalar @lines." lines at ($x,$y)\n";
    for my $i (0 .. scalar @lines-1)
      { 
      substr($fb[$y+$i], $x, length($lines[$i])) = $lines[$i]; 
      }
    }

  my $out = '';

  for my $y (0..$max_y)
    {
    $out .= $fb[$y] . "\n";
    }

  $out;
  }

#############################################################################
# layout the graph

sub layout
  {
  my $self = shift;

  # XXX todo: find a better layout for all the nodes

  ###########################################################################
  # prepare our stack of things we need to do before we are finished

  my @V = $self->nodes();

  my @todo;				# actions still to do
  # for all nodes, reset their pos and push them on the todo stack
  foreach my $n (@V)
    {
    $n->{x} = undef;			# mark as not placed yet
    $n->{y} = undef;
    push @todo, $n;			# node needs to be placed
    foreach my $o ($n->successors())
      {
#      use Data::Dumper; print Dumper($n), Dumper($o);
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

  my $step = 0;
  TRY:
  while (@todo > 0)			# all actions on stack done?
    {
    $step ++;
#    sleep(1) if $self->{debug};
    
    print STDERR "\n# Step $step: Score is $score\n" if $self->{debug};

    # pop one action
    my $action = shift @todo;

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
          # insert action to place target before hand
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
    my $path = Graph::Simple::Node->new( name => "\n -->", border => 'none', w => 5 );
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
    my $path = Graph::Simple::Node->new( name => "  |\n  |\n  v", border => 'none', w => 5, h => 3);
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
    my $path = Graph::Simple::Node->new( name => "\n <--", border => 'none', w => 5);
    $cells->{"$x,$y"} = $path;
    $path->{x} = $x;
    $path->{y} = $y;
    $mod = 3;				# straight +1, left +1, short +1
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

sub add_edge
  {
  my ($self,$x,$y,$edge) = @_;

  # register the nodes with ourself
  $x->{graph} = $self;
  $y->{graph} = $self;

  # add edge from X to Y (and X and Y)
  $self->SUPER::add_edge( $x->{name}, $y->{name} );

  # store $x and $y
  $self->set_attribute( 'obj', $x->{name}, $x);
  $self->set_attribute( 'obj', $y->{name}, $y);

  $edge = Graph::Simple::Edge->new() unless defined $edge;

  # store the edge, too
  $self->set_attribute( 'obj', $x->{name}, $y->{name}, $edge);

#  # add the two nodes (does work if x or y is already in the graph)
#  $self->{graph}->{$x->{id}} = $x;
#  $self->{graph}->{$y->{id}} = $y;
#
#  $edge = Graph::Simple::Edge->new() unless defined $edge;

#  # link them
#  $x->link($y);

  $self->{score} = undef;			# invalidate last layout

  $self;
  }

sub add_node
  {
  my ($self,$x) = @_;

  $self->SUPER::add_vertex( $x->{name} );
  $self->set_attribute( 'obj', $x->{name}, $x);

  $self->{score} = undef;			# invalidate last layout

  $self;
  }

sub nodes
  {
  # return all nodes as objects
  my ($self) = @_;

  my @nodes = ();

  my @V = $self->vertices();
  foreach my $k (@V)
    {
    push @nodes, $self->get_attribute( 'obj', $k );
    }
  @nodes;
  }

sub edge
  {
  # return an edge between two nodes as object
  my ($self, $x,$y) = @_;

  # turn objects into names (e.g. unique key)
  $x = $x->{name} if ref $x;
  $y = $y->{name} if ref $y;

  $self->get_attribute( 'obj', $x, $y );
  }

sub node
  {
  # return node by name
  my $self = shift;
  my $name = shift || '';

  $self->get_attribute( 'obj', $name );
  }

1;
__END__
=head1 NAME

Graph::Simple - Layout graphs as 2D boxes on a flat plane

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
	
	print $graph->as_html( );

	# creating a graph from a textual description	
	use Graph::Simple::Parser;
	my $parser = Graph::Simple::Parser->new();

	my $graph = $parser->from_text(
		'[ Bonn ] => [ Berlin ]'.
		'[ Berlin ] => [ Rostock ]'.
	);
	print $graph->as_ascii( );

=head1 DESCRIPTION

C<Graph::Simple> lets you generate graphs consisting of various shaped
boxes connected with arrows.

Be default it works on a grid, and thus the output is most usefull for flow
charts, network diagrams, or hirarchy trees.

=head2 Input

Apart from driving the module with Perl code, you can also use
C<Graph::Simple::Parser> to parse simple graph descriptions like:

	[ Bonn ]      --> [ Berlin ]
	[ Frankfurt ] <=> [ Dresden ]
	[ Bonn ]      --> [ Frankfurt ]

See L<Output> for how this will be rendered in ASCII art.

=head2 Output

The output can be done in various styles:

=over 2

=item ASCII ART

Uses things like C<+>, C<-> C<< < >> and C<|> to render the boxes.

=item BOX ART

Uses the extended ASCII characters to draw seamless boxes.

=item HTML

HTML tables with CSS making everything "pretty".

=back

=head1 EXAMPLES

=head1 METHODS

C<Graph::Simple> supports the following methods:

=head2 new()

        use Graph::Simple;

        my $graph = Graph::Simple->new( );
        
Creates a new, empty C<Graph::Simple> object.

Takes optinal a hash reference with a list of options. The following are
valid options:

	debug			if true, enables debug output

=head2 score()

	my $score = $graph->score();

Returns the score of the graph, or undef if L<layout()> has not yet bee called.

Higher scores are better, although you cannot compare scores for different
graphs. The score should only be used to compare different layouts of the same
graph against each other:

	my $max = undef;

	$graph->randomize();
	my $seed = $graph->seed(); 

	$graph->layout();
	$max = $graph->score(); 

	for (1..10)
	  {
	  $graph->randomize();			# select random seed
	  $graph->layout();			# layout with that seed
	  if ($graph->score() > $max)
	    {
	    $max = $graph->score();		# store the new max store
	    $seed = $graph->seed();		# and it's seed
	    }
	  }

	# redo the best layout
	$graph->seed($seed);
	$graph->layout();

=head2 error()

	my $error = $graph->error();

Returns the last error. Optionally, takes an error message to be set.

	$graph->error( 'Expected Foo, but found Bar.' );

=head2 layout()

=head2 as_ascii()

	print $graph->as_ascii();

Return the graph layout in ASCII art.

=head2 as_html()

	print $graph->as_html();

Return the graph layout as HTML page with embedded CSS.

=head2 as_txt()

	print $graph->as_txt();

Return the graph as a textual representation, that can be parsed with
C<Graph::Simple::Parser> back to a graph.

This does not call L<layout()> since the actual text representation
is more a dump of the grpah, then a certain layout.

=head2 add_edge()

	$graph->add_edge( $x, $y, $edge);
	$graph->add_edge( $x, $y);

Add an edge between nodes X and Y. The optional edge object defines
the style of the edge, if not present, a default object will be used.

C<$x> and C<$y> should be objects of L<Graph::Simple::Node>, while
C<$edge> should be L<Graph::Simple::Edge>.
 
=head2 add_vertex()

	$graph->add_vertex( $x );

Add a single node X to the graph. C<$x> should be a L<Graph::Simple::Node>.

=head2 vertices()

	my $vertices = $graph->vertices();

In scalar context, returns the number of nodes/vertices the graph has.
In list context returns a list of all vertices (as their unique keys). See
also L<nodes()>.

=head2 nodes()

	my $nodes = $graph->nodes();

In scalar context, returns the number of nodes/vertices the graph has.
In list context returns a list of all the node objects (as reference).

=head2 node()

	my $node = $graph->node('node name');

Return node by name (case sensitive). Returns undef of the node couldn't be found.

=head2 edge()

	my $edge = $graph->edge( $node1, $node2 );

Return edge object between nodes C<$node1> and C<$node2>. Both nodes can be
either names of C<Graph::Simple::Node> objects.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Layout::Aesthetic>, L<Graph> and L<Graph::Simple::Parser>.

There is also an very old, unrelated project from ca. 1995, which does something similiar.
See L<http://rw4.cs.uni-sb.de/users/sander/html/gsvcg1.html>.

=head1 AUTHOR

Tels L<http://bloodgate.com>

=head1 LICENSE

Copyright (C) 2004 by Tels

This library is free software; you can redistribute it and/or modify
it under the same terms of the GPL. See the LICENSE file for information.

=cut
