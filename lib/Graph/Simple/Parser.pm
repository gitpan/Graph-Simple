#############################################################################
# Parse text definition into a Graph::Simple object
#
# (c) by Tels 2004 - 2005.
#############################################################################

package Graph::Simple::Parser;

use 5.006001;
use strict;
use warnings;
use Graph::Simple;

use vars qw/$VERSION/;

$VERSION = '0.06';

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

  $self;
  }

sub reset
  {
  # reset the status of the parser, clear errors etc.
  my $self = shift;

  $self->{error} = '';

  $self;
  }

sub from_file
  {
  my ($self,$file) = @_;

  open PARSER_FILE, $file or die (ref($self).": Cannot read $file: $!");
  local $/ = undef;			# slurp mode
  my $doc = <PARSER_FILE>;		# read entire file
  close PARSER_FILE;

  $self->from_text($doc);
  }

sub from_text
  {
  my ($self,$txt) = @_;

  $self->reset();

  my $graph = Graph::Simple->new( { debug => $self->{debug} } );

  return $graph if !defined $txt || $txt =~ /^\s*\z/;		# empty text?

  my @lines = split /\n/, $txt;

  my $c = 'Graph::Simple::Node';
  my $e = 'Graph::Simple::Edge';
  my $nr = -1;

  # rgeexp for the different parts
  my $qr_node = _match_node();
  my $qr_attr = _match_attributes();
  my $qr_oatr = _match_optional_attributes();
  my $qr_edge = _match_edge();

  # for "[ 1 ] -> [ 2 ]" we push "2" on the stack and when we encounter
  # " -> [ 3 ]" treat the stack as a node-list left of "3"
  my @stack = ();

  my $backbuffer = '';	# left over fragments to be combined with next line
  LINE:
  while (@lines > 0 || $backbuffer ne '')
    {
    $nr++;

    my $curline = '';
    
    if (@lines > 0)
      {
      $curline = shift @lines;
      next if $curline =~ /^\s*#/;	# starts with '#' or '\s+#' => comment so skip
      next if $curline =~ /^\s*\z/;	# empty line?
      }
    
    chomp($curline);

    my $line = $backbuffer . $curline;

    # convert #808080 into \#808080
    $line =~ s/:\s*(#[a-fA-F0-9]{3,6})/: \\$1/g;

    # remove comment at end of line (but leave \# alone):
    $line =~ s/[^\\]#.*//;

    # remove white space at start/end
    $line =~ s/^\s+//;
    $line =~ s/\s+\z//;

    # node { color: red; } or 
    # node.graph { color: red; }

    if ($line =~ /^(node|graph|edge|group)(\.\w+)?$qr_attr\z/)
      {
      my $type = $1 || '';
      my $class = $2 || '';
      my $att = $self->_parse_attributes($3 || '');

      return undef unless defined $att;		# error in attributes?

      $graph->set_attributes ( "$type$class", $att);

      @stack = ();
      }
    # [ Berlin ]
    elsif ($line =~ /^$qr_node\z/)
      {
      my $n1 = $1;
      # strip trailing spaces
      $n1 =~ s/\s*\z//;
      # unquote special chars
      $n1 =~ s/\\([\[\(\{\}\]\)#])/$1/g;

      my $node_a = $graph->node($n1);
      if (!defined $node_a)
        {
        $node_a = $c->new( { name => $n1 } ); 
        $graph->add_node ( $node_a );
        }
      @stack = ($node_a);
      }
    # [ Berlin ] { color: red; }
    elsif ($line =~ /^$qr_node$qr_attr\z/)
      {
      my $n1 = $1;
      my $a1 = $self->_parse_attributes($2||'');
      # strip trailing spaces
      $n1 =~ s/\s*\z//;
      # unquote special chars
      $n1 =~ s/\\([\[\(\{\}\]\)#])/$1/g;

      my $node_a = $graph->node($n1);
      if (!defined $node_a)
        {
        $node_a = $c->new( { name => $n1 } ); 
        $graph->add_node ( $node_a );
        }

      $node_a->set_attributes($a1);
      @stack = ($node_a);
      }
    # [ Berlin ] -> [ Kassel ]
    elsif ($line =~ /^$qr_node$qr_oatr$qr_edge$qr_node$qr_oatr/)
      {
      my $n1 = $1; 				# left node name
      my $n3 = $4; my $en = $5 || '';		# edge style and label
      my $n6 = $8;				# right node name
      my $a1 = $2 || ''; my $a2 = $9 || '';	# left/right node attributes

      my $att1 = $self->_parse_attributes($a1);
      my $att2 = $self->_parse_attributes($a2);

      # strip trailing spaces
      $n1 =~ s/\s*\z//;
      $n6 =~ s/\s*\z//;
      $en =~ s/\s*\z//;
     
      # unquote special chars
      $n1 =~ s/\\([\[\(\{\}\]\)#])/$1/g;
      $n6 =~ s/\\([\[\(\{\}\]\)#])/$1/g;

      my $node_a = $graph->node($n1);
      my $node_b = $graph->node($n6);

      $node_a = $c->new( { name => $n1 } ) unless defined $node_a;
      $node_b = $c->new( { name => $n6 } ) unless defined $node_b;

      $node_a->set_attributes ($att1);
      $node_b->set_attributes ($att2);

      my $style = '--';	# default
      $style = '==' if $n3 =~ /^=+\z/; 
      $style = '..' if $n3 =~ /^\.+\z/; 
      $style = '- ' if $n3 =~ /^(- )+\z/; 
      # XXX TODO: look at $n2 and $n4 for left/right direction
      my $edge = $e->new( { style => $style . '>', name => $en } );
      $graph->add_edge ( $node_a, $node_b, $edge );
      @stack = ($node_b);
      $line =~ s/^$qr_node$qr_oatr$qr_edge$qr_node$qr_oatr//;
      $backbuffer = $line;
      next LINE;
      }
    # node chain continued like "-> [ Kassel ]"
    elsif (@stack != 0 && $line =~ /^$qr_edge$qr_node$qr_oatr/)
      {
      my $n = $6;					# node name
      my $ed = $2; my $en = $3 || '';			# edge style and label
      my $a1 = $self->_parse_attributes($7||'');	# node attributes

      # strip trailing spaces
      $n =~ s/\s*\z//;
      $en =~ s/\s*\z//;
      # unquote special chars
      $n =~ s/\\([\[\(\{\}\]\)#])/$1/g;

      my $node_b = $graph->node($n);
      $node_b = $c->new( { name => $n } ) unless defined $node_b;

      my $att1 = $self->_parse_attributes($a1);
      $node_b->set_attributes ($att1);
      
      my $style = '--';	# default
      $style = '==' if $ed =~ /^=+\z/; 
      $style = '..' if $ed =~ /^\.+\z/; 
      $style = '- ' if $ed =~ /^(- )+\z/; 

      my $edge = $e->new( { style => $style . '>', name => $en } );

      # add edges for all nodes in the left list
      foreach my $node_a (@stack)
        {
        $graph->add_edge ( $node_a, $node_b, $edge );
        }
 
      # remember the right side
      @stack = ($node_b);

      $line =~ s/^$qr_edge$qr_node$qr_oatr//;
      $backbuffer = $line;
      next LINE;
      }
    else
      {
      # couldn't handle that fragement, so accumulate it
      last LINE if @lines == 0;			# but not if it is the very last

      $backbuffer .= $curline;
      @stack = ();
      next LINE;
      }

    # for all handled cases
    $backbuffer = '';
    }

   if ($backbuffer ne '')
    { 
    $self->error("'$backbuffer' not recognized by parser.");
    return undef;
    }

  $graph;
  }

sub _match_attributes
  {
  # return a regexp that matches something like " { color: red; }" and returns
  # the inner text without the {}
  qr/\s*\{\s*([^\}]+?)\s*\}/;
  }

sub _match_optional_attributes
  {
  # return a regexp that matches something like " { color: red; }" and returns
  # the inner text without the {}
  qr/(\s*\{\s*[^\}]+?\s*\})?/;
  }

sub _match_node
  {
  # return a regexp that matches something like " [ bonn ]" and returns
  # the inner text without the [] (might leave some spaces)
  qr/\s*\[\s*([^\]]+?[^\\])\]/;
  }

sub _match_edge
  {
  # matches an edge, like:
  # <--, <==, <.. etc
  # -->, ---->, ==> etc
  # <-->, <---->, <==>, <..> etc
  # - Text -->

  # "- " must come before "-"!

  qr/\s*(<?)(=|- |-|\.)+([^=\.>-]*?)(=|- |-|\.)*(>?)/;
  }

sub _parse_attributes
  {
  # takes a text like "attribute: value;  attribute2 : value2;" and
  # returns a hash with the attributes
  my ($self,$text) = @_;

  my $att = {};

  $text =~ s/^\s*\{//;		# remove left-over {
  $text =~ s/\}\s*\z//;		# remove left-over }

  my @atts = split /\s*;\s*/, $text;

  foreach my $a (@atts)
    {
    $self->error ("Error in atttribute: '$a' doesn't look valid to me.")
      and return undef 
    unless ($a =~ /^[^:]+:[^:]+\z/);	# name: value

    my ($name, $val) = split /\s*:\s*/, $a;
    $name =~ s/^\s+//;			# strip space at front
    $name =~ s/\s+$//;			# strip space at end
    $val =~ s/^\s+//;			# strip space at front
    $val =~ s/\s+$//;			# strip space at end

    $att->{$name} = $val;
    }
  $att;
  }

sub error
  {
  my $self = shift;

  $self->{error} = $_[0] if defined $_[0];
  $self->{error};
  }

1;
__END__

=head1 NAME

Graph::Simple::Parser - Parse graph from textual description

=head1 SYNOPSIS

        # creating a graph from a textual description
        use Graph::Simple::Parser;
        my $parser = Graph::Simple::Parser->new();

        my $graph = $parser->from_text(
                '[ Bonn ] => [ Berlin ]'.
                '[ Berlin ] => [ Rostock ]'.
        );
        print $graph->as_ascii( );

=head1 DESCRIPTION

C<Graph::Simple::Parser> lets you parse simple textual descriptions
of graphs, and constructs a C<Graph::Simple> object from them.

The resulting object can than be used to layout and output the graph.

=head2 Input

The input consists of text describing the graph.

	[ Bonn ]      --> [ Berlin ]
	[ Frankfurt ] <=> [ Dresden ]
	[ Bonn ]      --> [ Frankfurt ]
	[ Bonn ]      ==> [ Frankfurt ]

See L<Output> for how this will be rendered in ASCII art.

The edges between the nodes can have the following styles:

	-->		line
	==>		double line
	..>		dotted
	- >		dashed

In additon the following three directions are possible:

	 -->		connect the node on the left to the node on the right
	<-->		the direction between the nodes
			goes into both directions at once
	<--		connect the node on the right to the node on the left

Of course you can combine all three directions with all styles.

=head2 Output

The output will be a L<Graph::Simple> object, see there for what you
can do with it.

=head1 EXAMPLES

See L<Graph::Simple> for an extensive list of examples.

=head1 METHODS

C<Graph::Simple::Parser> supports the following methods:

=head2 new()

	use Graph::Simple::Parser;
	my $parser = Graph::Simple::Parser->new();

Creates a new parser object.

=head2 reset()

	$parser->reset();

Reset the status of the parser, clear errors etc.

=head2 from_text()

	my $graph = $parser->from_text( $text );

Create a L<Graph::Simple> object from the textual description in C<$text>.

Returns undef for error, you can find out what the error was
with L<error()>.

This method will reset any previous error, and thus the C<$parser> object
can be re-used to parse different texts by just calling C<from_text()>
multiple times.

=head2 from_file()

	my $graph = $parser->from_file( $filename );

Creates a L<Graph::Simple> object from the textual description in the file
C<$filename>.

Returns undef for error, you can find out what the error was
with L<error()>.

=head2 error()

	my $error = $parser->error();

Returns the last error.

=head2 _parse_attributes()

	my $attributes = $parser->_parse_attributes( $txt );
  
Takes a text like this:

	attribute: value;  attribute2 : value2;

and returns a hash with the attributes.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Simple>.

=head1 AUTHOR

Copyright (C) 2004 - 2005 by Tels L<http://bloodgate.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms of the GPL. See the LICENSE file for information.

=cut
