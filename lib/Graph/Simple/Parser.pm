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

$VERSION = '0.05';

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
  local $\ = "\n";			# slurp mode
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
  LINE:
  foreach my $line (@lines)
    {
    $nr++;
    chomp($line);

    next if $line =~ /^\s*#/;	# starts with '#' or '\s+#' => comment so skip
    next if $line =~ /^\s*\z/;	# empty line?
    
    # remove comment (but leave \# intact):
    $line =~ s/[^\\]#.*//;

    # remove white space at start/end
    $line =~ s/^\s+//;
    $line =~ s/\s+\z//;

#    print STDERR "at line $nr '$line'\n";

    # node { color: red; } or 
    # node.graph { color: red; }

    if ($line =~ /^(node|graph|edge|group)(\.\w+)?\s*\{([^\}]+)\}\s*\z/)
      {
      my $type = $1 || '';
      my $class = $2 || '';
      my $att = $self->_parse_attributes($3 || '');

      return undef unless defined $att;		# error in attributes?

      $graph->set_attributes ( "$type$class", $att);

      next LINE;
      }
    
    # [ Berlin ]
    if ($line =~ /^\[\s*([^\]]+?)\s*\]\z/)
      {
      my $n1 = $1;
      # unquote special chars
      $n1 =~ s/\\([\[\(\{\}\]\)#])/$1/g;

      my $node_a = $graph->node($n1);
      if (!defined $node_a)
        {
        $node_a = $c->new( { name => $n1 } ); 
        $graph->add_node ( $node_a );
        }
      next LINE;
      }

    # [ Berlin ] -> [ Kassel ]
    #                      1              2    3     4                 6
    if ($line =~ /^\[\s*([^\]]+?)\s*\]\s*(<?)((=|-|- |\.)+)(>?)\s*\[\s*([^\]]+?)\s*\]/)
      {
      my $n1 = $1; my $n6 = $6; my $n3 = $3;

      # unquote special chars
      $n1 =~ s/\\([\[\(\{\}\]\)#])/$1/g;
      $n6 =~ s/\\([\[\(\{\}\]\)#])/$1/g;

      my $node_a = $graph->node($n1);
      my $node_b = $graph->node($n6);

      $node_a = $c->new( { name => $n1 } ) unless defined $node_a;
      $node_b = $c->new( { name => $n6 } ) unless defined $node_b;

      my $style = '--';	# default
#      print STDERR "edge style '$n3'\n";
      $style = '==' if $n3 =~ /^=+\z/; 
      $style = '..' if $n3 =~ /^\.+\z/; 
      $style = '- ' if $n3 =~ /^(- )+\z/; 
#      print STDERR "edge style '$style'\n";
      # XXX TODO: look at $n2 and $n4 for left/right direction
      my $edge = $e->new( { style => $style . '>' } );
      $graph->add_edge ( $node_a, $node_b, $edge ); 
      next LINE;
      }

    $self->error("'$line' not recognized by parser.") and return undef;
    }

  $graph;
  }

sub _parse_attributes
  {
  # takes a text like "attribute: value;  attribute2 : value2;" and
  # returns a hash with the attributes
  my ($self,$text) = @_;

  my $att = {};

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
