#!/usr/bin/env perl

use Text::TabFile;
use strict;

my $panels = new Text::TabFile ('Master Schedule Document- F2 2025 - Panels To Schedule.tsv', 1);

while ( my $ref = $panels->Read ) {
	my $id = $ref->{'Pretalx ID'};
	my $title = $ref->{'Panel / Event Title:'};
	my $hosts = $ref->{'Hosted by:'};
	my $guests = $ref->{'Special Guests'};

	my $desc = $ref->{'Event / Panel Description:'};

	print "<h3>$title</h3>\n",
	      "<b>Hosted By: $hosts</b><br />\n",
	      ( $guests ? "<b>Special Guests: $guests</b><br />\n" : "" ),
          "<p>$desc</p>\n\n";
}
