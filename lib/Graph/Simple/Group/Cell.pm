#############################################################################
# (c) by Tels 2004 - 2005. Part of Graph::Simple
#
#############################################################################

package Graph::Simple::Group::Cell;

use 5.006001;
use strict;
use Graph::Simple::Node;
require Exporter;

use vars qw/$VERSION @ISA @EXPORT_OK/;

@ISA = qw/Graph::Simple::Node Exporter/;

$VERSION = '0.01';

@EXPORT_OK = qw/
  GROUP_INNER
  GROUP_RIGHT
  GROUP_LEFT
  GROUP_TOP
  GROUP_BOTTOM
  GROUP_ALL

  GROUP_MAX
  /;

#############################################################################

# The different types for a group-cell:
sub GROUP_INNER	 	() { 0; }	# completely sourounded by group cells
sub GROUP_RIGHT	 	() { 1; }	# right border only
sub GROUP_LEFT	 	() { 2; }	# left border only
sub GROUP_TOP	 	() { 3; }	# top border only
sub GROUP_BOTTOM 	() { 4; }	# bottom border only
sub GROUP_ALL	 	() { 5; }	# completely sourounded by non-group cells
sub GROUP_BOTTOM_RIGHT	() { 6; }	# bottom and right border
sub GROUP_BOTTOM_LEFT	() { 7; }	# bottom and left border
sub GROUP_TOP_RIGHT	() { 8; }	# top and right border
sub GROUP_TOP_LEFT	() { 9; }	# top and left order

sub GROUP_MAX		() { 9; }	# max number

my $border_styles = 
  {
  # type    	    top,	bottom, left,   right,	class
  GROUP_INNER()	 => [ 0,	0,	0,	0,	''],
  GROUP_RIGHT()	 => [ 0,	0,	0,	1,	'-r' ],
  GROUP_LEFT()	 => [ 0,	0,	1,	0,	'-l' ],
  GROUP_TOP()	 => [ 1,	0,	0,	0,	'-t' ],
  GROUP_BOTTOM() => [ 0,	1,	0,	0,	'-b' ],
  GROUP_ALL()	 => [ 0,	0,	0,	0,	'-all' ],
  GROUP_BOTTOM_RIGHT() => [ 0,	1,	0,	1,	'-br' ],
  GROUP_BOTTOM_LEFT() => [ 0,	1,	1,	0,	'-bl' ],
  GROUP_TOP_RIGHT() => [ 1,	0,	0,	1,	'-tr' ],
  GROUP_TOP_LEFT() => [ 1,	0,	1,	0,	'-tl' ],
  };

my $border_name = [ 'top', 'bottom', 'left', 'right' ];

sub _css
  {
  my ($c, $id, $type, $group, $border) = @_;

  my $b = $border_styles->{$type};
  
  # If border eq 'none', this would needlessly repeat the "border: none"
  # from the general group class.
  return '' if $border eq 'none';

  my $cl = ".group$b->[4]"; $cl .= "-$group" unless $group eq '';
  my $css = "table.graph$id $cl {";
  for (my $i = 0; $i < 4; $i++)
    {
    $css .= " border-$border_name->[$i]: $border;" if $b->[$i];
    }
  $css .= " border: $border;" if $type == GROUP_ALL;	# shorter CSS
  $css .= "}\n";

  $css;
  }

# Define the neighbour-patterns. If a cell matches this pattern, it is of that
# type. '1' means the cell belongs to the same group, '0' means no or another
# group, '.' means don't care. Index:

  # +------+--------+-------+
  # | 0     1         2     |
  # +      +        +       +
  # | 7               3     |
  # +      +        +       +
  # | 6      5        4     |
  # +------+--------+-------+

my $neighbours = 
  {
  #01234567
  '.1.1.1.1' => GROUP_INNER, 
  '.0.1.1.1' => GROUP_TOP, 
  '.1.1.0.1' => GROUP_BOTTOM, 
  '.1.1.1.0' => GROUP_LEFT, 
  '.1.0.1.1' => GROUP_RIGHT, 
  '.1.0.0.1' => GROUP_BOTTOM_RIGHT, 
  '.1.1.0.0' => GROUP_BOTTOM_LEFT, 
  '.0.0.1.1' => GROUP_TOP_RIGHT, 
  '.0.1.1.0' => GROUP_TOP_LEFT, 
  '.0.0.0.0' => GROUP_ALL, 
  };

#############################################################################

sub _init
  {
  # generic init, override in subclasses
  my ($self,$args) = @_;
  
  $self->{type} = GROUP_INNER;
  $self->{class} = 'group';
  $self->{name} = '';
  
  $self->{x} = 0;
  $self->{y} = 0;
  $self->{w} = 0; #undef;
  $self->{h} = 0;

  # XXX TODO check arguments
  foreach my $k (keys %$args)
    {
    $self->{$k} = $args->{$k};
    }
 
  if (defined $self->{group})
    {
    # register ourselves at this group
    $self->{group}->add_cell ($self);
    $self->{class} = $self->{group}->{class};
    $self->{class} = 'group' unless defined $self->{class};
    # to make "group($name)" work
    $self->{groups}->{ $self->{group}->{name} } = $self->{group};
    } 
  $self->{error} = '';

  $self;
  }

sub _set_type
  {
  # set the proper type of this cell based on the sourrounding cells
  my ($self, $cells) = @_;

  # XXX TODO:

  # +------+--------+-------+
  # | LT     TOP      RU    |
  # +      +        +       +
  # | LEFT   INNER    Right |
  # +      +        +       +
  # | LB     BOTTOM   RB    |
  # +------+--------+-------+

  my @coord = (
    [ -1,-1 ],
    [  0,-1 ],
    [ +1,-1 ],
    [ +1, 0 ],
    [ +1,+1 ],
    [  0,+1 ],
    [ -1,+1 ],
    [ -1, 0 ],
    );

  my $pattern = '';
  my ($sx,$sy) = ($self->{x},$self->{y});
  foreach my $co (@coord)
    {
    my ($x,$y) = @$co; $x += $sx; $y += $sy;
    my $belongs = '0';
    my $cell = $cells->{"$x,$y"};
#    print STDERR "$x $y = $cell\n";
    $belongs = '1' if ref($cell) && defined $cell->group($self->{group}->{name});
    $pattern .= $belongs;
    }

#  print STDERR "cell $self->{x}, $self->{y} $pattern\n";

  foreach my $p (keys %$neighbours)
    {
    if ($pattern =~ /^$p/)
      {
   #   print STDERR "$pattern matches $p\n";
      $self->{type} = $neighbours->{$p};
      # replace subclass
      my $new = 'group' . $border_styles->{$self->{type}}->[4];
  
      $self->{class} =~ s/^group[^.]*/$new/;
      last;
      } 
    }
  
  $self;
  }

sub type
  {
  my $self = shift;

  $self->{type};
  }

#############################################################################
# conversion to ASCII or HTML

#sub as_ascii1
#  {
#  my ($self) = @_;
#
#  # XXX TODO: 
#  '';
#
##  $self->{group}->{name} = $self->_content(0);
##
###  print STDERR "path: as_html: $self->{group}->{name} ($nr)\n";
##  
##  # let Graph::Simple::Edge (aka Node) handle the output: 
##  $self->{group}->as_ascii(@_);
#  }

sub error
  {
  my $self = shift;

  $self->{error} = $_[0] if defined $_[0];
  $self->{error};
  }

#############################################################################

# for rendering this path element as ASCII, we need to correct our width based
# on whether we have a border or not. But this is only known after parsing is
# complete.

sub _correct_w
  {
  my $self = shift;

  my $border = $self->{group}->attribute('border') || 'none';
  if (!defined $self->{w})
    {
    if ($border eq 'none')
      {
      $self->{w} = 0;
      }
    else
      {
      $self->{w} = 2;
      }
    }

#    my $border = $self->{group}->attribute('border') || 'none';
#    # XXX TODO
#    my @lines = split /\n/, $self->_content(0);
#    
#    # find longest line
#    my $chars = 0;
#    foreach my $line (@lines)
#      {
#      $chars = length($line) if length($line) > $chars;
#      }
#
#    if ($border eq 'none')
#      {
#      $self->{w} = $chars + 1;
#      }
##    else
#      {
#      $self->{w} = $chars + 4;
#      }
#    }
  }

#############################################################################
# a cell simple uses the attributes from the group it belongs to

sub attribute
  {
  my ($self, $atr) = @_;

#  return $self->{group}->attribute($atr) if defined $self->{group};
  $self->SUPER::attribute($atr);
  }

1;
__END__

=head1 NAME

Graph::Simple::Group::Cell - A cell in a group

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

A C<Graph::Simple::Group::Cell> represents a cell of a group.

Group cells can have a background and, if they are on the outside, a border.

=head1 METHODS

=head2 error()

	$last_error = $group->error();

	$group->error($error);			# set new messags
	$group->error('');			# clear error

Returns the last error message, or '' for no error.

=head2 as_ascii()

	my $ascii = $cell->as_ascii();

Returns the cell as a little ascii representation.

=head2 as_html()

	my $html = $cell->as_html($tag,$id);

Returns the cell as HTML code.

=head2 label()

	my $label = $cell->label();

Returns the name (also known as 'label') of the cell.

=head1 EXPORT

None.

=head1 TODO

=over 2

=item Labels

=item Borders

=back

=head1 SEE ALSO

L<Graph::Simple>.

=head1 AUTHOR

Copyright (C) 2004 - 2005 by Tels L<http://bloodgate.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL. See the LICENSE file for more details.

=cut