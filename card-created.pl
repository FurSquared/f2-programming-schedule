#!/usr/bin/env perl

# Check the schedule and list card created in order for the reference tab

use Data::Dumper qw/Dumper/;
use Text::TabFile;
use strict;

### Read the schedule

my $schedule = new Text::TabFile ('schedule.tab', 1);
my @header = $schedule->fields;

my @rooms = qw/Crystal Kilbourn MacArthur Miller Mitchell Other Pabst
               S201 Schlitz Usinger Walker Wright/;

my %data;

while ( my $row = $schedule->Read ) {
	my $time = $row->{'Room'};
	if ($time =~ /(AM|PM)/ ) { # These are scheduled panels
		for my $room (@rooms) {
			$data{$row->{$room}}++ if $row->{$room};
			$data{$row->{$room.'_1'}}++ if $row->{$room.'_1'};
			$data{$row->{$room.'_2'}}++ if $row->{$room.'_2'};
			$data{$row->{$room.'_3'}}++ if $row->{$room.'_3'};
		}
	} else { # These are cards in the parking lot
		for my $column (@rooms, 'Room') {
			for my $section ( qw/_1 _2 _3/ ) {
				my $test = $row->{$column.$section};
				$data{$test}++ if $test;
			}
		}
	}
}

# Check agaiinst the panels-to-schedule

my $ref = new Text::TabFile ('Master Schedule Document- F2 2025 - Panels To Schedule.tsv', 1);

while ( my $line = $ref->Read ) {
	my $panel = $line->{'Panel / Event Title:'};
	die unless $panel;

	my $card = $data{$panel} ? 'yes' : 'no';
	#print "$card\t$panel\n";
	print "$card\n";
}