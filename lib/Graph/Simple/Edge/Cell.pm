#############################################################################
# (c) by Tels 2004 - 2005. Part of Graph::Simple
#
#############################################################################

package Graph::Simple::Edge::Cell;

use 5.006001;
use strict;
use Graph::Simple::Edge;

use vars qw/$VERSION @EXPORT_OK @ISA/;
@ISA = qw/Exporter Graph::Simple::Edge/;

$VERSION = '0.01';

#############################################################################

# The different types for a path:
sub EDGE_SHORT_E	() { 0; }		# |->	a start/end at the same cell
sub EDGE_SHORT_N	() { 1; }		# v	a start/end at the same cell
sub EDGE_SHORT_W	() { 2; }		# <-|	a start/end at the same cell
sub EDGE_SHORT_S	() { 3; }		# ^	a start/end at the same cell

sub EDGE_START_E	() { 4; }		# |--	starting-point
sub EDGE_START_N	() { 5; }		# |	starting-point
sub EDGE_START_W	() { 6; }		# --|	starting-point
sub EDGE_START_S	() { 7; }		# |	starting-point

sub EDGE_END_E		() { 8; }		# -->	end-point
sub EDGE_END_N		() { 9; }		# ^	end-point
sub EDGE_END_W		() { 10; }		# <--	end-point
sub EDGE_END_S		() { 11; }		# v	end-point

sub EDGE_HOR		() { 12; }		# --	horizontal line
sub EDGE_VER		() { 13; }		# |	vertical line
sub EDGE_CROSS		() { 14; }		# +	crossing lines
sub EDGE_N_E		() { 15; }		# |_	corner (N to E)
sub EDGE_N_W		() { 16; }		# _|	corner (N to W)
sub EDGE_S_E		() { 17; }		# ,-	corner (S to E)
sub EDGE_S_W		() { 18; }		# -,	corner (S to W)

# Joints:
sub EDGE_S_E_W		() { 19; }		# -,-	three-sided corner (S to W and S to E)
sub EDGE_N_E_W		() { 20; }		# -'-	three-sided corner (N to W and N to E)
sub EDGE_E_N_S		() { 21; }		# -|	three-sided corner (E to S and N)
sub EDGE_W_N_S		() { 22; }		#  |-	three-sided corner (W to S and N)

sub EDGE_MAX_TYPE () { 22; }	# last valid type

@EXPORT_OK = qw/
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
  EDGE_N_E
  EDGE_N_W
  EDGE_S_E
  EDGE_S_W

  EDGE_S_E_W
  EDGE_N_E_W
  EDGE_E_N_S
  EDGE_W_N_S	

  /;

my $edge_styles = 
  {
  # style  hor, ver,   right, left, up, down, cross
  '--' => [ '--', "|\n|",   '>',   '<',  '^',   'v',   '+' ],		# simple line
  '==' => [ '==', "||\n||", '>',   '<',  '/\\', '\\/', "++\n++"],	# double line
  '..' => [ '..', ":\n:",   '>',   '<',  '^',   'v',   ' ' ],		# dotted
  '- ' => [ '- ', "|\n ",   '>',   '<',  '^',   'v',   '+' ],		# dashed
  };

my @edge_content = 
  (
  # "^", "v", "--" and "|\n|" are replaced by the different styles from above

  # ASCII,		HTML,			# type
  "\n -->",		'------>',		# EDGE_SHORT_E
  "  ^\n  |  \n  |",	"^\n|\n|",		# EDGE_SHORT_N
  "\n <--",		'<------',		# EDGE_SHORT_W
  "  |\n  |\n  v",	"|\n|\nv",		# EDGE_SHORT_S

  "\n ----",	'------',			# EDGE_START_E
  "|\n|\n",	"|\n|\n|\n|\n",			# EDGE_START_N
  "\n---- ",	'------',			# EDGE_START_W
  "\n |\n |\n",	"\n|\n|\n|\n|",			# EDGE_START_S

  "\n--> ",	'------>',			# EDGE_END_E
  "^\n|\n|",	"^\n|\n|",			# EDGE_END_N
  "\n <--",	'<------',			# EDGE_END_W
  " |\n |\n v",	"|\n|\nv",			# EDGE_END_S

  '----',	'------',			# EDGE_HOR
  " |\n |\n |\n |",	"|\n|\n|\n|\n|\n|",	# EDGE_VER
  " |\n|\n|\n|",	"|\n|\n|\n|\n|\n|",	# EDGE_CROSS
  );

#############################################################################

sub _init
  {
  # generic init, override in subclasses
  my ($self,$args) = @_;
  
  $self->{type} = EDGE_SHORT_E;
  $self->{style} = '--';
  
  $self->{x} = 0;
  $self->{y} = 0;
  $self->{w} = undef;
  $self->{h} = 3;

  # XXX TODO check arguments
  foreach my $k (keys %$args)
    {
    $self->{$k} = $args->{$k};
    }
 
  if (defined $self->{edge})
    {
    # register ourselves at this edge
    $self->{edge}->add_cell ($self);
    # take over settings from edge
    $self->{style} = $self->{edge}->{style};
    $self->{class} = $self->{edge}->{class};
    $self->{graph} = $self->{edge}->{graph};
    $self->{att} = $self->{edge}->{att};
    } 
  $self->{error} = '';

  $self;
  }

#############################################################################
# conversion to ASCII or HTML

sub _content
  {
  my ($self, $offset) = @_;

  my $nr = ($self->{type} << 1);
  my $name = $edge_content[ $nr + $offset];

  my $style = $edge_styles->{ $self->{style} };
  # '--' => [ "|\n|",   '>',   '<',  '^',   'v',   '+' ],		# simple line
  my @replace = ( '--', qr/\|\n\s*\|/, '>', '<', '^', 'v', "+" ); 

  my $i = 0;
  for my $repl (@$style)
    {
    my $q = quotemeta($replace[$i]);
    $name =~ s/$q/$repl/g if $replace[$i] ne $repl;
    $i++;
    }

  $name;
  }

sub as_ascii
  {
  my $self = shift;

  # XXX TODO: include our label
  $self->{name} = $self->_content(0);

  # let Graph::Simple::Edge (aka Node) handle the output: 
  $self->SUPER::as_ascii(@_);
  }

sub as_html
  {
  my ($self) = shift;
  
  $self->{name} = $self->_content(1);

  my $id = $self->{graph}->{id};

  my $noquote = 0;
  # if we have a label, and are a EDGE_SHORT_E/EDGE_SHORT_W
  my $label = $self->{att}->{label};
  $label = '' unless defined $label;

  my $type = $self->{type};
  if ($label ne '')
    {
    if(($type == EDGE_SHORT_E) ||
       ($type == EDGE_SHORT_W))
      {
      my $left = '';
      my $right = '';
      $left = '&lt;' if $type == EDGE_SHORT_W;
      $right = '&gt;' if $type == EDGE_SHORT_E;
      # twice the length of the label is about right, due to 0.7 * 0.8
      # (letter-spacing * font-size) being about 1.8 plus some spacing left/right
      my $length = int(2 + 0.90 * length($label));

      $self->{name} = 
      "<span class='label'>$label</span><br>" .
      "<span class='line'>$left" . ($self->{style} x $length) . "$right</span>\n";
      $noquote = 1;
      $self->{class} = 'edgel';
      } 
    elsif (($type == EDGE_SHORT_N) ||
          ($type == EDGE_SHORT_S))
      {
      my $name = $self->{name}; 
      $name =~ s/&/&amp;/g;
      $name =~ s/</&lt;/g;
      $name =~ s/</&gt;/g;
      $name =~ s/\n/<br>/g;
 
      $self->{name} = 
      "$name<span class='labelv'>$label</span>\n";
      $noquote = 1;
      $self->{class} = 'edgev';
      }
    } # end of label handling code 

#  print STDERR "path: as_html: '$label' $self->{name}\n";

  # let Graph::Simple::Edge (aka Node) handle the output: 
  $self->SUPER::as_html($_[0], $_[1], $noquote);
  }

sub error
  {
  my $self = shift;

  $self->{error} = $_[0] if defined $_[0];
  $self->{error};
  }

#############################################################################
# accessor methods

sub label
  {
  my $self = shift;

  my $n = $self->{name}; $n = '' unless defined $n;

  $n;
  }

sub type
  {
  # get/set type of this path element
  # type - EDGE_START, EDGE_END, EDGE_HOR, EDGE_VER, etc
  my ($self,$type) = @_;

  if (defined $type)
    {
    if (defined $type && $type < 0 || $type > EDGE_MAX_TYPE)
      {
      require Carp;
      Carp::croak ("Cell type $type for cell $self->{x},$self->{y} is not valid.");
      }
    $self->{type} = $type;
    }

  $self->{type};
  }

#############################################################################

# for rendering this path element as ASCII, we need to correct our width based
# on whether we have a border or not. But this is only known after parsing is
# complete.

sub _correct_w
  {
  my $self = shift;

  if (!defined $self->{w})
    {
    my $border = $self->{edge}->attribute('border') || 'none';
    # XXX TODO
    my @lines = split /\n/, $self->_content(0);
    
    # find longest line
    my $chars = 0;
    foreach my $line (@lines)
      {
      $chars = length($line) if length($line) > $chars;
      }

    if ($border eq 'none')
      {
      $self->{w} = $chars + 1;
      }
    else
      {
      $self->{w} = $chars + 3;
      }
    }
  }

#############################################################################
# attribute handling

sub attribute
  {
  my ($self, $atr) = @_;

  return $self->{att}->{$atr} if exists $self->{att}->{$atr};

  # if not set, path simple uses the attributes from the edge it belongs to
  $self->{edge}->attribute($atr);
  }

1;
__END__

=head1 NAME

Graph::Simple::Edge::Cell - A path-element in an edge

=head1 SYNOPSIS

        use Graph::Simple::Path;
        use Graph::Simple::Edge;

	my $ssl = Graph::Simple::Edge->new(
		label => 'encrypted connection',
		style => '-->',
		color => 'red',
	);
	my $path = Graph::Simple::Path->new(
		type => EDGE_SHORT_E,
	);
	$ssl->add_cell ($path);

	my $src = Graph::Simple::Node->new(
		name => 'source',
	);

	my $dst = Graph::Simple::Node->new(
		name => 'destination',
	);

	$graph = Graph::Simple->new();

	$graph->add_edge($src, $dst, $ssl);

	print $graph->as_ascii();

=head1 DESCRIPTION

A C<Graph::Simple::Path> represents an edge between two (or more) nodes in a
simple graph.

Each edge has a direction (from source to destination, or back and forth),
plus a style (line width and style), colors etc. It can also have a name,
e.g. a text associated with it.

=head1 METHODS

=head2 error()

	$last_error = $edge->error();

	$cvt->error($error);			# set new messags
	$cvt->error('');			# clear error

Returns the last error message, or '' for no error.

=head2 as_ascii()

	my $ascii = $path->as_ascii();

Returns the path-cell as a little ascii representation.

=head2 as_html()

	my $html = $path->as_html($tag,$id);

Returns the path-cell as HTML code.

=head2 label()

	my $label = $path->label();

Returns the name (also known as 'label') of the path-cell.

=head2 style()

	my $style = $edge->style();

Returns the style of the edge.

=head1 EXPORT

None by default. Can export the following on request:

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
  EDGE_N_E
  EDGE_N_W
  EDGE_S_E
  EDGE_S_W

  EDGE_S_E_W
  EDGE_N_E_W
  EDGE_E_N_S
  EDGE_W_N_S	

=head1 TODO

Different ASCII styles:

   ,-----, 	       +-----+
   | Foo | --,    vs.  | Foo |  --+
   |_____|   |         +-----+    |
	     |	                  |

=head1 SEE ALSO

L<Graph::Simple>.

=head1 AUTHOR

Copyright (C) 2004 - 2005 by Tels L<http://bloodgate.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL. See the LICENSE file for more details.

=cut