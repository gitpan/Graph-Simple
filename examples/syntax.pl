#!/usr/bin/perl -w

#############################################################################
# This script tries to generate graphs from all the files in t/syntax/
# and outputs the result as an HTML page.
# Use it like:

# ewxamples/syntax.pl >test.html

# and then open test.html in your favourite browser.

BEGIN
  {
  chdir 'examples' if -d 'examples'; 
  use lib '../lib';
  }

use strict;
use warnings;
use Graph::Simple::Parser;

my $parser = Graph::Simple::Parser->new();

my @toc = ();

open FILE, 'syntax.tpl' or die ("Cannot read 'syntax.tpl': $!");
local $/ = undef;
my $html = <FILE>;
close FILE;

my $output = ''; my $ID = '0';

# generate the parts and push their names into @toc
gen_graphs($parser);

my $toc = '<ul>';
for my $t (@toc)
  {
  my $n = $t; $n =~ s/\s/_/;
  $toc .= " <li><a href=\"#$n\">" . $t . "</a>\n";
  }
$toc .= "</ul>\n";

# insert the TOC
$html =~ s/##TOC##/ $toc /;
$html =~ s/##HTML##/ $output /;
$html =~ s/##time##/ scalar localtime() /e;
$html =~ s/##version##/$Graph::Simple::VERSION/e;

print $html;

# all done;

1;

#############################################################################

sub gen_graphs
  {
  # for all files in a dir, generate a graph from it
  my $parser = shift;

  _for_all_files($parser, 'syntax');
  _for_all_files($parser, 'stress');
  }

sub _for_all_files
  {
  my ($parser, $dir) = @_;

  opendir DIR, "../t/$dir" or die ("Cannot read dir '../t/$dir': $!");
  my @files = readdir DIR;
  closedir DIR;

  foreach my $file (sort @files)
    {
    my $f = "../t/$dir/" . $file;
    next unless -f $f;			# not a file?
 
    open FILE, "$f" or die ("Cannot read '$f': $!");
    local $/ = undef;
    my $input = <FILE>;
    close FILE;
    my $graph = $parser->from_text( $input );

    if (!defined $graph)
      {
      $output .=
        "<h2>$dir/$file" .
	"<a class='top' href='#top' title='Go to the top'>Top -^</a></h2>\n".
	"<div class='text'>\n".
	"Error: Could not parse input from $file: <b style='color: red;'>" . $parser->error() . "</b>".
	"<br>Input was:\n" .
	"<pre>$input</pre>\n".
	"</div>\n";
      next;
      }
    $output .= out ($input, $graph, 'html');
    }
  }

sub out
  {
  my ($txt,$graph,$method) = @_;

  $method = 'as_' . $method;

  # set unique ID for CSS
  $graph->id($ID++);
  
  my $t = $graph->nodes() . ' Nodes, ' . $graph->edges . ' Edges';
  my $n = $t; $n =~ s/\s/_/;
  
  push @toc, $t;

  "<style type='text/css'>\n" .
  "<!--\n" .
  $graph->css() . 
  "-->\n" .
  "</style>\n" .

  "<a name=\"$n\"></a><h2>$t\n" .
  "<a class='top' href='#top' title='Go to the top'>Top -^</a></h2>\n".
   "<div class='text'>\n" .
 
   "<div style='float: left;'>\n" . 
   "<h3>Input</h3>\n" . 
   "<pre>$txt</pre></div>" . 

   "<div style='float: left;'>\n" . 
   "<h3>As Text</h3>\n" . 
   "<pre>" . $graph->as_txt() . "</pre></div>" . 

   "<div style='float: left;'>\n" . 
   "<h3>As HTML:</h3>\n" . 
   $graph->$method() . "</div>\n" .

   "<div class='clear'>&nbsp;</div></div>\n\n";
  }

