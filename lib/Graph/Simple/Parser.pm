#############################################################################
# Parse text definition into a Graph::Simple object
#
# (c) by Tels 2004 - 2005.
#############################################################################

package Graph::Simple::Parser;

use 5.006001;
use strict;
use Graph::Simple;

use vars qw/$VERSION/;

$VERSION = '0.08';

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

  # regexps for the different parts
  my $qr_node = _match_node();
  my $qr_attr = _match_attributes();
  my $qr_oatr = _match_optional_attributes();
  my $qr_edge = _match_edge();
  my $qr_comma = _match_comma();

  my $qr_group_start = _match_group_start();
  my $qr_group_end   = _match_group_end();

  # for "[ 1 ] -> [ 2 ]" we push "2" on the stack and when we encounter
  # " -> [ 3 ]" treat the stack as a node-list left of "3"
  # in addition, for " [ 1 ], [ 2 ] => [ 3 ]", the leftstack will contain
  # "1" and "2" when we encounter "3"
  my @stack = ();

  my @group_stack = ();	# all the (nested) groups we are currently in
  my $backbuffer = '';	# left over fragments to be combined with next line

  ###########################################################################
  # main parsing loop

  LINE:
  while (@lines > 0 || $backbuffer ne '')
    {
    my $curline = '';
    
    if (@lines > 0)
      {
      $nr++;
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

    #print STDERR "# at line '$line' stack: ", join(",", @stack),"\n";

    # node { color: red; } or 
    # node.graph { color: red; }
    # XXX TODO: group-label, edge-label
    if ($line =~ /^(node|graph|edge|group)(\.\w+)?$qr_attr\z/)
      {
      my $type = $1 || '';
      my $class = $2 || '';
      my $att = $self->_parse_attributes($3 || '');

      return undef unless defined $att;		# error in attributes?

      $graph->set_attributes ( "$type$class", $att);

      # forget stack
      @stack = ();

      # and current line
      $line = '';
      }
    # ( group start [
    elsif ($line =~ /^$qr_group_start/)
      {
      my $gn = $1 || '';			# group name

      # strip trailing spaces
#      $gn =~ s/\s*\z//;
      # unquote special chars
      $gn =~ s/\\([\[\(\{\}\]\)#])/$1/g;

      my $group = $graph->group ($gn);
      if (!defined $group)
        {
        $group = Graph::Simple::Group->new( { name => $gn } );
        $graph->add_group ($group);
        }
      push @group_stack, $group;

      $line =~ s/^$qr_group_start/\[/;
      }
    # ) # group end
    elsif ($line =~ /^$qr_group_end$qr_oatr/)
      {

      if (@group_stack == 0)
        {
        $self->error("Found unexpected group end at line $nr");
        return undef;
        }
      my $group = pop @group_stack;

      my $a1 = $self->_parse_attributes($1||'');	# group attributes
      $group->set_attributes($a1);

      $line =~ s/^$qr_group_end$qr_oatr//;
      }
    # [ Berlin ] { color: red; }
    elsif ($line =~ /^$qr_node$qr_oatr/)
      {
      my $n1 = $1;
      my $a1 = $self->_parse_attributes($2||'');

      my $node_a = $self->_new_node ($graph, $n1, \@group_stack, $a1);

      @stack = ($node_a);

      $line =~ s/^$qr_node$qr_oatr//;
      }
    # , [ Berlin ] { color: red; }
    elsif ($line =~ /^$qr_comma$qr_node$qr_oatr/)
      {
      my $n1 = $1;
      my $a1 = $self->_parse_attributes($2||'');

      my $node_a = $self->_new_node ($graph, $n1, \@group_stack, $a1);

      @stack = ($node_a);

      $line =~ s/^$qr_comma$qr_node$qr_oatr//;
      }
    # Things like "[ Node ]" will be consumed before, so we do not need a case
    # for "[ A ] -> [ B ]":
    # node chain continued like "-> { ... } [ Kassel ] { ... }"
    elsif (@stack != 0 && $line =~ /^$qr_edge$qr_oatr$qr_node$qr_oatr/)
      {
      my $n = $7;					# node name
      my $ed = $2 || ''; my $en = $3 || '';		# edge style and label
      my $ed2 = $4 || '';
      my $ea = $6 || '';				# save edge attributes
      my $a1 = $self->_parse_attributes($8||'');	# node attributes
      $ea = $self->_parse_attributes($ea);		# parse edge attributes

      # strip trailing spaces
      $en =~ s/\s*\z//;

      my $node_b = $self->_new_node ($graph, $n, \@group_stack, $a1);
      
      my $style = '--';	# default
      $style = '==' if $ed =~ /^=+\z/; 
      $style = '..' if $ed =~ /^\.+\z/; 
      $style = '- ' if $ed =~ /^(- )+\z/; 

      # add edges for all nodes in the left list
      foreach my $node (@stack)
        {
        my $edge = $e->new( { style => $style, name => $en } );
        $edge->set_attributes($ea);
#        print STDERR "# continued: edge from $node->{name} => $node_b->{name}\n";

	# XXX TODO: what happens if edge already exists?

        $graph->add_edge ( $node, $node_b, $edge );
        }
#      print STDERR "# handled stack\n";
 
      # remember the right side
      @stack = ($node_b);

      $line =~ s/^$qr_edge$qr_oatr$qr_node$qr_oatr//;
      }
    else
      {
      # couldn't handle that fragement, so accumulate it
      last LINE if @lines == 0;			# but not if it is the very last

      $line = $backbuffer . $curline;
      }

    $backbuffer = $line;
    }

   if ($backbuffer ne '')
    { 
    $self->error("'$backbuffer' not recognized by parser.");
    return undef;
    }

  $graph;
  }

sub _new_node
  {
  # create a new node unless it doesn't already exist. If the group stack
  # contains entries, the new node appears first in this/these group(s), so
  # add it to these groups.
  my ($self, $graph, $name, $group_stack, $att) = @_;
      
  # strip trailing spaces
  $name =~ s/\s*\z//;
  # unquote special chars
  $name =~ s/\\([\[\(\{\}\]\)#])/$1/g;

  my $node = $graph->node($name);

  if (!defined $node)
    {
    $node = Graph::Simple::Node->new( { name => $name } );
    $graph->add_node($node); 
    }

  $node->add_to_groups(@$group_stack) if @$group_stack != 0;

  $node->set_attributes ($att);

  $node;
  }

sub _match_comma
  {
  # return a regexp that matches something like " , " like in:
  # "[ Bonn ], [ Berlin ] => [ Hamburg ]"
  qr/\s*,\s*/;
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
  # the inner text with the {}
  #qr/(\s*\{\s*[^\}]+?\s*\})?/;
  qr/(\s*\{[^\}]+?\})?/;
  }

sub _match_node
  {
  # return a regexp that matches something like " [ bonn ]" and returns
  # the inner text without the [] (might leave some spaces)
  qr/\s*\[\s*([^\]]+?[^\\])\]/;
  }

sub _match_group_start
  {
  # return a regexp that matches something like " ( group [" and returns
  # the text between "(" and "["
  qr/\s*\(\s*([^\[]+?)\s*\[/;
  }

sub _match_group_end
  {
  # return a regexp that matches something like " )".
  qr/\s*\)\s*/;
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
    unless ($a =~ /^\s*([^:]+?)\s*:\s*(.+?)\s*\z/);	# "name: value"

    my ($name, $val) = ($1,$2);

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

Returns the last error, or the empty string if no error occured.

=head2 _parse_attributes()

	my $attributes = $parser->_parse_attributes( $txt );
  
B<Internal usage only>. Takes a text like this:

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
