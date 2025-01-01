#!/usr/bin/env perl

use Data::Dumper qw/Dumper/;
use String::Similarity;
use Text::TabFile;
use strict;

### Read the panel list

my $panels = new Text::TabFile ('panels.tab', 1);
my %panels;

while ( my $ref = $panels->Read ) {
	$panels{$ref->{'Panel / Event Title:'}}++;
}

#print Dumper(\%panels);

print scalar(keys %panels), " panels found on the master list.\n";

### Read the schedule

my $schedule = new Text::TabFile ('schedule.tab', 1);
my @header = $schedule->fields;


my @rooms = qw/Crystal Kilbourn MacArthur Miller Mitchell Other Pabst
               S201 Schlitz Usinger Walker Wright/;

my %data;

while ( my $row = $schedule->Read ) {
	my $time = $row->{'Room'};
	for my $room (@rooms) {
		$data{'thursday'}{$room}{$time} = $row->{$room}      if $row->{$room};
		$data{'friday'}{$room}{$time}   = $row->{$room.'_1'} if $row->{$room.'_1'};
		$data{'saturday'}{$room}{$time} = $row->{$room.'_2'} if $row->{$room.'_2'};
		$data{'sunday'}{$room}{$time}   = $row->{$room.'_3'} if $row->{$room.'_3'};
	}
}

my $count = 0;

for my $day (keys %data) {
	for my $room (keys %{$data{$day}}) {
		for my $time (sort keys %{$data{$day}{$room}}) {
			$count++;
		}
	}
}

print "$count panels found in the schedule.\n";

#print Dumper(\%data);

### Check things

print "==> CHECKING\n";

for my $day (keys %data) {
	for my $room (keys %{$data{$day}}) {
		for my $time (sort keys %{$data{$day}{$room}}) {
			my $scheduled_panel = $data{$day}{$room}{$time};
			next if $scheduled_panel =~ /^CLOSED$/i;
			print "$scheduled_panel\n";
			unless ( $panels{$scheduled_panel} ) {
				print "\tWARNING: Panel doesn't exist!\n" unless $panels{$scheduled_panel};
				my $guess = nearest($scheduled_panel);
				print "\tShould it be \"$guess\"?\n" if $guess;
			}
			print "\n";
		}
	}
}

sub nearest {
	my $name_to_check = shift @_;
	my $guess_score = 0;
	my $guess_name = undef;
	for my $panel_name (keys %panels) {
		my $test = similarity($name_to_check, $panel_name);
		if ($test > $guess_score) {
			$guess_name = $panel_name;
			$guess_score = $test;
		}
	}
	return $guess_score >= 0.75 ? $guess_name : undef;
}