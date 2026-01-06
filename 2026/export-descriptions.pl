#!/usr/bin/env perl

use Text::TabFile;
use strict;

my $panels = new Text::TabFile ('panels.tab', 1);

my %fields = (
	id => 'ID',
	title => 'Panel / Event Title:',
	hosts => 'Hosted by:',
	guests => 'Special Guests',
	desc => 'Event / Panel Description:',
	age => 'Does this event contain Mature Content?'
);

my @data;

while ( my $ref = $panels->Read ) {
        next unless $ref->{'Rating'} =~ /A/;
	my %panel;
	map {$panel{$_} = $ref->{$fields{$_}}} keys %fields;
	push @data, \%panel;
}

for my $p (sort { lc($a->{'title'}) cmp lc($b->{'title'}) } @data) {
	my $age_warn = '';
	$age_warn = ' (18+)' if $p->{'age'} =~ /^18/;
	$age_warn = ' (21+)' if $p->{'age'} =~ /^21/;

	print "<font size=+1><b><u>", $p->{'title'}, $age_warn, "</font></b></u><br />\n",
	      "<b>Hosted By: ", $p->{'hosts'},
	      ( $p->{'guests'} ? " with ".$p->{'guests'} : "" ),
		  "</b><br />\n",
          "<p>", $p->{'desc'}, "</p>\n\n";
}
