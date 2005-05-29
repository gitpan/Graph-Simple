#############################################################################
# Convert pod with =begin graph paragraphs as HTML.
#
# (c) by Tels 2005.
#############################################################################

package Graph::Simple::Pod2HTML;

use 5.006001;
require Exporter;
use Pod::Simple::HTML;
use Graph::Simple;
use Graph::Simple::Parser;
use strict;
use vars qw/$VERSION @ISA @EXPORT_OK /;

@ISA = qw/Pod::Simple::HTML Exporter/;
@EXPORT_OK = qw/go/;

$VERSION = '0.01';

BEGIN
  {
  $|++;
  }

#############################################################################

sub new
  {
  my $class = shift;
  
  my $self = $class->SUPER::new(@_);

  $self->accept_targets(qw/ graph graph-common /);

  # our own namespace to store stuff under
  $self->{_graph} = {}; my $g = $self->{_graph};

  # reusable parser object for the graph paragraphs
  $g->{parser} = Graph::Simple::Parser->new();

  $g->{id} = ''; 	# counting ID for each graph (first one is empty)
  $g->{state} = 0;	# 0: outside graph, 1: graph, 2: common parts
  $g->{common} = '';	# no common texts as default
  $g->{css} = '';	# start with empty CSS
  $g->{css_file} = '';	# no CSS file for now

  $self->{Tagmap}->{"/head2"} = "</a></h2>\n\n<div class='text'>\n\n";
  $self->{Tagmap}->{"head2"} = "</div>\n\n<h2>";

  my $header = 
<<EOF
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
 <title>
EOF
  ;
  
  $header =~ s/\n\z//;
  $self->html_header_before_title($header);

  $header = 
<<EOF2
 </title>
 <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
 <meta name="MSSmartTagsPreventParsing" content="TRUE">
 <meta http-equiv="imagetoolbar" content="no">
</head>
<body bgcolor=white text=black>
##version##
<a name="___top"></a>

<div class="menu">

  <p class="menuext"><a class="menuext" href="index.html" title="Back to the main page">Main</a></p>

</div>

<div class="right">

  <div class="dummy"> <!-- dummy div to be closed by first h2 that follows it -->

EOF2
  ;

  $header =~ s/^\n//;
  $header =~ s/##version##/ $self->version_tag_comment(); /eg;

  $self->html_header_after_title($header);

  # set default footer contents
  $self->footer_contents('');

  $self->footer_contents(
   "Generated at " . scalar localtime() . " by " . __PACKAGE__ . " v$VERSION");

  $self;
  }

#############################################################################
# customizations:

sub footer_contents
  {
  # get/set the contents of the footer paragraph. Pass '' to disable footer box.
  my $self = shift;
  my $footertext = shift;

  if (defined $footertext)
    {
    $self->{_graph}->{footertext} = $footertext;

    my $footer;

    if ($footertext eq '')
      {
      $footer = <<EOF3

  </div>

  </div> <!-- end right side -->
  <!-- end doc -->
</body></html>
EOF3
      ;
      }
    else
      {
    $footer = <<EOF3

  </div>

  <div class="footer">
  ##footer##
  </div>

  </div> <!-- end right side -->
  <!-- end doc -->
</body></html>
EOF3
      ;

      $footer =~ s/##footer##/$footertext/;
      }
    $self->html_footer($footer);
    }

  $self->{_graph}->{footertext};
  }

sub css_file
  {
  # return the accumulated CSS code
  my $self = shift;

  $self->{_graph}->{css_file} = $_[0] if defined $_[0];
  $self->{_graph}->{css_file};
  }

#############################################################################
#############################################################################

sub _add_top_anchor
  {
  # we override this one to inhibit a second useless top anchor
  }

sub html_css
  {
  # return the accumulated CSS code
  my $self = shift;

  print STDERR "html_css called" . join(" ", caller()) . " " . length($self->{_graph}->{css}) . "\n";

  my $css_file = $self->css_file();

  my $css = '';
  $css = ' <link rel="stylesheet" type="text/css" href="' . "$css_file\">\n"
    if $css_file ne ''; 

  $css . " <style type='text/css'><!--\n" .
         $self->{_graph}->{css} .
         " --> </style>"; 
  }

sub go
  {
  my $self = __PACKAGE__->new();

  $self->parse_from_file(@_);
  }

#############################################################################
#############################################################################

sub _handle_element_start
  {
  my($self, $element_name, $att) = @_;

  return $self->SUPER::_handle_element_start($element_name,$att)
    if $element_name ne 'for' || $att->{target} !~ /^graph/;

  #print "handle start $element_name\n";

  my $g = $self->{_graph};
  my $parser = $g->{parser}; 	# get the reusable parser object

  $parser->reset();
  $g->{state} = 1;		# note that we are inside graph
  $g->{state} = 2 if $att->{target} eq 'graph-common';

  return;
  }

sub _handle_element_end 
  {
  my($self, $element_name) = @_;

  my $g = $self->{_graph};

  return $self->SUPER::_handle_element_end($element_name)
    unless $element_name eq 'for' && $g->{state} > 0;

#  print "handle end $element_name\n";

  if ($g->{state} == 1)		# handled a graph
    {
    $g->{id}++; 		# next graph get's a new ID

    my $fh = $self->output_fh;
#    use Devel::Peek;
#    print Dump($fh);

    print STDERR "outputting\n";
    print $fh $g->{output};
#    $fh->autoflush();
#    $fh->flush();
#    $fh->printflush( $g->{output} ); 
    delete $g->{output};
    }

  $g->{state} = 0;		# outside of graph again

  return;
  }

sub _handle_text
  {
  my($self, $text) = @_;

  my $g = $self->{_graph};

#  print "handle text $text\n";

  return $self->SUPER::_handle_text($text)
    unless $g->{state} > 0;
    
  if ($g->{state} == 2)		# found graph-common parts
    {
    $g->{common} = $text."\n";	# store for later usage
    return;
    }
 
  # get the reusable parser object
  my $parser = $g->{parser};
  # create a graph object from the common parts plus the current text
  $g->{graph} = $parser->from_text( $g->{common} . $text);

  if (!defined $g->{graph})
    {
    # something went wrong, like an parser error (invalid input etc)
    $g->{output} .= 'Error: ' . $parser->error();
    }
  else
    {
    # and give it the running ID
    $g->{graph}->id( $g->{id} );

    print STDERR $g->{graph}->css() . "\n";

    print STDERR $self->pod_para_count(),"\n";

    $g->{css} .= $g->{graph}->css(); 

    $g->{output} .= $g->{graph}->as_html();
#    $g->{output} .= "<style type='text/css'><!--\n" .
#		$g->{graph}->css() . 
#	      "--> </style>\n" . 	
#		$g->{graph}->as_html();
    }

  return;
  }

1;
__END__
=head1 NAME

Graph::Simple::Pod2HTML - Render pod with graph code as HTML

=head1 SYNOPSIS

	perl -MGraph::Simple::Pod2HTML=go -e 'go thingy.pod'
	
=head1 DESCRIPTION

C<Graph::Simple::Pod2HTML> uses L<Pod::Simple::HTML> to render POD
as HTML. In addition to Pod::Simple::HTML, it also handles paragraphs
of the type C<graph> like shown here:

	=for graph [ A ] => [ B ]

	=begin graph

	 [ A ] => [ B ] -> [ C ]
	 [ C ] => [ D ]

	=end graph

In addition to C<graph> code, you can also use C<graph-common> to
store graph code that should be common to all following graphs.
Each C<graph-common> paragraph will replace the former definition:

	This graph will have default settings:

	=for graph [ A ] => [ B ]

	Store now a different background color:

	=begin graph-common

	graph { background: #deadff; }
	node { background: #fff000; }

	=end graph-common

	This graph will use the common part defined above:

	=for graph [ A ] => [ B ]

	This will replace the common parts with only a
	blue background for nodes:

	=for graph-common node { background: blue; }

	So this graph will have blue nodes:

	=for graph [ A ] => [ B ]

More info about the graph code can be found at L<http://bloodgate.com/perl/graph/>.

=head1 METHODS

=head2 new()

	$converter = Graph::Simple::Pod2HTML->new();

Creates a new converter object, which takes pod and emit's HTML.

=head2 go()

	$conveter->go( $filename );

Parse C<$filename> and emit HTML on STDOUT.

=head1 CUSTOMIZATION

The following methods can be used to customize the appearance and the
contents of the output of Graph::Simple::Pod2HTML:

=head2 footer_contents

	$footer = $converter->footer_contents();	# query
	$converter->footer_contents('');		# disable
	$converter->footer_contents('Hello HTML!');	# set

This method let's you decide whether you want a final footer paragraph,
or not, and what it should contain. The default is a timestamp and the
version of Graph::Simple::Pod2HTML.

=head2 css_file

	$converter->css_file('');			# none
	$converter->css_file('base.css');		# base.css

This method can be used to set the name of an external stylesheet file
that should be linked from the generated document.

=head1 EXPORT

Exports nothing, but can export C<go()> on request.

=head1 SEE ALSO

L<Graph::Simple>, L<Pod::Simple>.

More info about the graph code can be found at L<http://bloodgate.com/perl/graph/>.

=head1 AUTHOR

Copyright (C) 2005 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut
