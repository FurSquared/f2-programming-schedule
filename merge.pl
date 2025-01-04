#!/usr/bin/env perl

use Data::Dumper qw/Dumper/;
use Text::TabFile;
use strict;

my $ref = new Text::TabFile ('panels.tab', 1);

#my @header = $ref->fields();
#print Dumper(\@header);

my %dittman;
while ( my $line = $ref->Read ) {
	$dittman{$line->{'Panel ID'}} = $line;
}
#print Dumper(\%dittman);

my $ref = new Text::TabFile ('Master Schedule Document- F2 2025 - Panels To Schedule.tsv', 1);

#my @header = $ref->fields();
#print Dumper(\@header);

while ( my $line = $ref->Read ) {
	my $panel = $line->{'Panel / Event Title:'};
	#print "* $panel\n";
	die unless $panel;

	my $this_id;
	for my $id ( keys %dittman ) {
		#print "= '$id\n" if $dittman{$id}{'Panel / Event Title:'} eq $panel;
		$this_id = $id if $dittman{$id}{'Panel / Event Title:'} eq $panel;
	}

	print "'$this_id\n";
}
