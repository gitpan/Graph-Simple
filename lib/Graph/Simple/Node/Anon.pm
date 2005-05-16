#############################################################################
# (c) by Tels 2004. Part of Graph::Simple. An anonymous invisible node.
#
#############################################################################

package Graph::Simple::Node::Anon;

@ISA = qw/Graph::Simple::Node/;
$VERSION = 0.01;

use strict;

sub _init
  {
  my $self = shift;

  $self->SUPER::_init(@_);

  $self->{name} = '#' . $self->{id};
  $self->{w} = 3;
  $self->{h} = 3;
  $self->{class} = 'node.anon';

#  $self->attribute('shape', 'invisible');

  $self;
  }

sub _correct_w
  {
  $_[0];
  }

sub attributes_as_txt
  {
  '';
  }

sub as_ascii
  {
  # node is invisible
  "";
  }

sub as_pure_txt
  {
  '[ ]';
  }

sub as_graphviz_txt
  {
  my $self = shift;
  
  my $name = $self->{att}->{label}; $name = $self->{name} unless defined $name;

  # quote special chars in name
  $name =~ s/([\[\]\(\)\{\}\#])/\\$1/g;

  '"' .  $name . '"';
  }

sub as_txt
  {
  '[ ]';
  }

sub title
  {
  # Returns a title of the node (or '', if none was set), which can be
  # used for mouse-over titles
  '';
  }

#sub label
#  {
  # XXX TODO hack to make anon nodes really invisible in HTML (the CSS
  # *should* take care of that, but somehow doesn't work...)
#  '';
#  }

1;
__END__

=head1 NAME

Graph::Simple::Node::Anon - An anonymous, invisible node in a simple graph

=head1 SYNOPSIS

	use Graph::Simple::Node::Anon;

	my $anon = Graph::Simple::Node::Anon->new();

=head1 DESCRIPTION

A C<Graph::Simple::Node::Anon> represents an anonymous, invisible node in a
simple graph. These can be used to let edges start and end "nowhere".

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Graph::Simple::Node>.

=head1 AUTHOR

Tels L<http://bloodgate.com>

=head1 LICENSE

Copyright (C) 2004 - 2005 by Tels

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL. See the LICENSE file for more details.

=cut
