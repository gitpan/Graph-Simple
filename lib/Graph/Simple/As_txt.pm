#############################################################################
# output the graph as textual description
#
# (c) by Tels 2004-2005.
#############################################################################

package Graph::Simple::As_txt;

use vars qw/$VERSION/;

$VERSION = '0.01';

#############################################################################
#############################################################################

package Graph::Simple;

use strict;

sub as_txt
  {
  my ($self) = @_;

  # convert the graph to a textual representation
  # does not need a layout() before hand!

  # generate the class attributes first
  my $txt = '';
  my $att =  $self->{att};
  for my $class (sort keys %$att)
    {
    my $a = $att->{$class};
    my $att = '';
    for my $atr (keys %$a)
      {
      # attribute not defined
      next if !defined $a->{$atr};

      next if defined $self->{def_att}->{$class}->{$atr} &&
              $a->{$atr} eq $self->{def_att}->{$class}->{$atr};
      $att .= "  $atr: $a->{$atr};\n";
      }

    if ($att ne '')
      {
      # the following makes short, single definitions to fit on one line
      if ($att !~ /\n.*\n/ && length($att) < 40)
        {
        $att =~ s/\n/ /; $att =~ s/^  / /;
        }
      else
        {
        $att = "\n$att";
        }
      $txt .= "$class {$att}\n";
      }
    }

  $txt .= "\n" if $txt ne '';		# insert newline

  my @nodes = $self->sorted_nodes();

  my $count = 0;
  # output nodes with attributes first, sorted by their name
  foreach my $n (sort { $a->{name} cmp $b->{name} } @nodes)
    {
    $n->{_p} = undef;			# mark as not yet processed
    my $att = $n->attributes_as_txt();
    if ($att ne '')
      {
      $n->{_p} = 1;			# mark as processed
      $count++;
      $txt .= $n->as_pure_txt() . $att . "\n"; 
      }
    }
 
  $txt .= "\n" if $count > 0;		# insert a newline

  $count = 0;
  # output groups first, with their nodes
  foreach my $gn (sort keys %{$self->{groups}})
    {
    my $group = $self->{groups}->{$gn};
    $txt .= $group->as_txt();		# marks nodes as processed if nec.
    $count++;
    }

  $txt .= "\n" if $count > 0;		# insert a newline

  foreach my $n (@nodes)
    {
    my @out = $n->successors();
    my $first = $n->as_pure_txt();
    if ((@out == 0) && ( (scalar $n->predecessors() || 0) == 0))
      {
      # single node without any connections (unless already output)
      $txt .= $first . "\n" unless defined $n->{_p};
      }
    # for all outgoing connections
    foreach my $other (reverse @out)
      {
      my $edge = $self->edge( $n, $other );
      $txt .= $first . $edge->as_txt() . $other->as_pure_txt() . "\n";
      }
    }

  $txt;
  }
 
1;
__END__
=head1 NAME

Graph::Simple::As_txt - Generate textual description from graph object

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

	print $graph->as_txt();

	# prints something like:

	# [ Bonn ] -> [ Berlin ]

=head1 DESCRIPTION

C<Graph::Simple::As_txt> contains just the code for converting a
L<Graph::Simple|Graph::Simple> object to a human-readable textual description.

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
