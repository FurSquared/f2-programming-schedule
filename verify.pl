#!/usr/bin/env perl

use Data::Dumper qw/Dumper/;
use Text::TabFile;
use strict;

### Read the panel list

my $panels = new Text::TabFile ('Master Schedule Document- F2 2025 - Panels To Schedule.tsv', 1);
my %panels;

while ( my $ref = $panels->Read ) {
	$panels{$ref->{'Panel / Event Title:'}}++;
}

### Read the schedule

my $schedule = new Text::TabFile ('schedule.tab', 1);
my @header = $schedule->fields;


my @rooms = ('Baird Stage', 'Crystal Ball Room', 'Panel Room 1 [Banquet] Walker',
	'Panel Room 2 [Theater] Mitchell', 'Panel Room 3 [Theater] MacArthur',
	'Small Panel Room 1 [Friday Meetups] Pabst', 'Small Panel Room 2 [Theater] Schlitz',
	'Video Gaming Kilbourn', 'Tabletop Wright A/B', 'Miller', 'Usinger');

my %data;

while ( my $row = $schedule->Read ) {
	my $time = $row->{'Time\\Room'};
	for my $room (@rooms) {
		$data{'thursday'}{$room}{$time} = $row->{$room}      if $row->{$room};
		$data{'friday'}{$room}{$time}   = $row->{$room.'_1'} if $row->{$room.'_1'};
		$data{'saturday'}{$room}{$time} = $row->{$room.'_2'} if $row->{$room.'_2'};
		$data{'sunday'}{$room}{$time}   = $row->{$room.'_3'} if $row->{$room.'_3'};
	}
}

### Check things

print Dumper(\%panels);

for my $day (keys %data) {
	for my $room (keys %{$data{$day}}) {
		for my $time (sort keys %{$data{$day}{$room}}) {
			my $scheduled_panel = $data{$day}{$room}{$time};
			print "$scheduled_panel\n";
			print "\tWARNING: Panel doesn't exist!\n" unless $panels{$scheduled_panel};
		}
	}
}