#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 4;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Simple::Pod2HTML") or die($@);
   use_ok ("Graph::Simple") or die($@);
   };

can_ok ("Graph::Simple::Pod2HTML", qw/
  new
  go
  /);

#############################################################################

my $parser = Graph::Simple::Pod2HTML->new();

is (ref($parser), 'Graph::Simple::Pod2HTML');

