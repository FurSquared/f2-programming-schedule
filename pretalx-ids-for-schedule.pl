#!/usr/bin/env perl

# Figure out the Pretalx ID for the main panel list and put it in order

# export TOKEN=apitokenid
# make session1.json
# ./pretalx-ids-for-schedule.pl

use Data::Dumper qw/Dumper/;
use File::Slurp;
use JSON;
use Text::TabFile;
use strict;

# Slurp up the pretalx data. (from "Makefile session1.json")

my %lookup;

for my $i ( 1 .. 6 ) {
	my $json_data = read_file('session'.$i.'.json');
	my $pretalx_data = decode_json $json_data;
	my $submissions = $pretalx_data->{results};
	for my $sub (@$submissions) {
		$lookup{$sub->{'title'}}{$sub->{'code'}}++;
	}
}

#print Dumper(\%lookup);

# Process the panel tab and build output

my $ref = new Text::TabFile ('Master Schedule Document- F2 2025 - Panels To Schedule.tsv', 1);

while ( my $line = $ref->Read ) {
	my $name = $line->{'Panel / Event Title:'};
	my $id = (keys %{$lookup{$name}})[0];
	print join("\t", $id, $name), "\n";
}
