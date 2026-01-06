#!/usr/bin/env perl

use Text::TabFile;
use strict;

my $tf = new Text::TabFile ('panels.tab', 1);

while ( my $r = $tf->Read ) {
  my $id = $r->{'ID'};
  my $title = $r->{'Panel / Event Title:'};

  print "==========\n\t$title\n----------\n";

  if ( $r->{'Special Guests'} ) {
    print "Panelists: $r->{'Hosted by:'}; $r->{'Special Guests'}\n";
  } else {
    print "Panelists: $r->{'Hosted by:'} $r->{'Special Guests'}\n";
  }

  print "Avail: ";
  print avail_summary($r->{'Availability [Thursday]'});
  print ' ';
  print avail_summary($r->{'Availability [Friday]'});
  print ' ';
  print avail_summary($r->{'Availability [Saturday]'});
  print ' ';
  print avail_summary($r->{'Availability [Sunday]'});
  print "\n";

  print "Pref: ";
  print avail_summary($r->{'Preference [Thursday]'});
  print ' ';
  print avail_summary($r->{'Preference [Friday]'});
  print ' ';
  print avail_summary($r->{'Preference [Saturday]'});
  print ' ';
  print avail_summary($r->{'Preference [Sunday]'});
  print "\n";

  print "Length: ", $r->{'Event Length'}, "\n";
  print "Setup: ", $r->{'Setup time'}, "\n";
  print "Teardown: ", $r->{'Tear down time'}, "\n";
}

sub avail_summary {
  my $raw = shift @_;
  return 'X' if $raw =~ /Not Available/;
  return 'ABCD' if $raw =~ /Anytime/;
  my $out;
  $out .= 'A' if $raw =~ /Morning/;
  $out .= 'B' if $raw =~ /Afternoon/;
  $out .= 'C' if $raw =~ /Evening/;
  $out .= 'D' if $raw =~ /Late Night/;
  return $out if length($out) > 0;
  return '?';
}
