#!/usr/bin/env perl

use Data::Dumper qw/Dumper/;
use String::Similarity;
use Text::TabFile;
use strict;

### Read the panel list

my $panels = new Text::TabFile ('panels.tab', 1);

my %panels;
my %panelists;

while ( my $ref = $panels->Read ) {
	my $id = $ref->{'Panel ID'};
	my $title = $ref->{'Panel / Event Title:'};
	#warn("WARN: Skip! $id") if $ref->{'IN/OUT'} !~ /^IN/i;
    warn("WARN: Overwriting \"$title\" ($id vs $panels{$title}{'id'})") if defined $panels{$title};
	$panels{$title}{'id'} = $id;

	# Additional data
	$panels{$title}{'length'} = $ref->{'Event Length'};

	# Panelists
	if ( $ref->{'Hosted by:'} ) {
		for my $host ( split /\s*[,;\&]\s*/, $ref->{'Hosted by:'} ) {
			$panels{$title}{'panelists'}{$host}++;
			$panelists{$host}++;
		}
	} else {
		warn("WARN: $title ($id) has no host\n");
	}

	if ( $ref->{'Special Guests'} ) {
		for my $host ( split /\s*[,;\&]\s*/, $ref->{'Special Guests'} ) {
			$panels{$title}{'panelists'}{$host}++;
			$panelists{$host}++;
		}
	}

	# Input cleanup
	$panels{$title}{'length'} =~ s/\s+minutes\s*//ig;
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

print "==> Checking panels...\n";

for my $day (keys %data) {
	for my $room (keys %{$data{$day}}) {
		for my $time (sort keys %{$data{$day}{$room}}) {
			my $scheduled_panel = $data{$day}{$room}{$time};

			next if $scheduled_panel =~ /^CLOSED$/i;

			my $warnings = 0;
			my @info = ($scheduled_panel);

			# Does the scheduled panel exist in the panel list
			unless ( $panels{$scheduled_panel} ) {
				push(@info, "WARNING: Panel doesn't exist!") unless $panels{$scheduled_panel};
				my $guess = nearest($scheduled_panel);
				push(@info, "WARNING: Possibly a mispelling of \"$guess\"?") if $guess;
				$warnings++;
			}

			my $panel_ref = $panels{$scheduled_panel};

			# Check for panelist conflicts
			my @panelists = keys %{$panel_ref->{'panelists'}};
			push @info, "Panelists: " . join(", ", @panelists);

			for my $panelist (@panelists) {
				for my $test_room (keys %{$data{$day}}) {
					next if $test_room eq $room;
					my $test_panel = $data{$day}{$test_room}{$time};
					if ( exists($panels{$test_panel}{'panelists'}{$panelist}) ) {
						push @info, "WARNING: $panelist is double-booked in $room at $time on $test_panel";
						$warnings++;
					}
				}
			}

			# Display info with warnings
			print(join "\n\t", @info) if $warnings;
			print "\n\n" if $warnings;
		}
	}
}

### Subroutines

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