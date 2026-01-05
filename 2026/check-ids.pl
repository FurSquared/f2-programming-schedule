#!/usr/bin/env perl

use Data::Dumper qw/Dumper/;
use Text::TabFile;
use strict;

my %ids;

my $min = 10;
my $max = 0;

for my $file (@ARGV) {
  print "Opening $file\n";
  my $tf = new Text::TabFile ($file, 1);
  while ( my $row = $tf->Read ) {
    my $id = $row->{ID};
    $ids{$id}++;
    $max = $id if $id > $max;
    $min = $id if $id < $min;
  }
}

for my $i ( $min .. $max ) {
  my $test = sprintf("%03d", $i);
  next if $ids{$test};
  print "$test missing...\n";
}

