#!/usr/bin/env perl

use Data::Dumper qw/Dumper/;
use String::Similarity;
use Text::TabFile;
use strict;

=head1 Check the schedule against the panel list

 * Does the scheduled panel exist in the panel list?
 * Are there panelist conflicts? (multiple panels at the same time)
 * Have we scheduled this panel more than once?
 * Is there enough time for the panel length
 * Is the pabel scheduled at an avaible and/or preferred panelist time?

=cut

### Read the panel list

my %dittman_time_code;
map {$dittman_time_code{$_} = 'A'} ('9:00 AM', '9:30 AM', '10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM', '12:00 PM', '12:30 PM');
map {$dittman_time_code{$_} = 'B'} ('1:00 PM', '1:30 PM', '2:00 PM', '2:30 PM', '3:00 PM', '3:30 PM', '4:00 PM', '4:30 PM');
map {$dittman_time_code{$_} = 'C'} ('5:00 PM', '5:30 PM', '6:00 PM', '6:30 PM', '7:00 PM', '7:30 PM', '8:00 PM', '8:30 PM');
map {$dittman_time_code{$_} = 'D'} ('9:00 PM', '9:30 PM', '10:00 PM', '10:30 PM', '11:00 PM', '11:30 PM', '12:00 AM', '12:30 AM', '1:00 AM', '1:30 AM');

my @times = ('9:00 AM', '9:30 AM', '10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM', '12:00 PM', '12:30 PM',
	'1:00 PM', '1:30 PM', '2:00 PM', '2:30 PM', '3:00 PM', '3:30 PM', '4:00 PM', '4:30 PM', '5:00 PM', '5:30 PM',
    '6:00 PM', '6:30 PM', '7:00 PM', '7:30 PM', '8:00 PM', '8:30 PM', '9:00 PM', '9:30 PM', '10:00 PM', '10:30 PM',
    '11:00 PM', '11:30 PM', '12:00 AM', '12:30 AM', '1:00 AM', '1:30 AM');
my %next_time;
for my $i (0 .. $#times) {
	$next_time{$times[$i]} = $times[$i+1] if $i+1 <= $#times;
}

my $panels = new Text::TabFile ('Master Schedule Document- F2 2025 - Panels To Schedule.tsv', 1);

my %panels; # complex hash of panel data, keyed by name
my %panelists; # counting hash of panelist names

while ( my $ref = $panels->Read ) {
	my $id = $ref->{'Dittman ID'};
	my $title = $ref->{'Panel / Event Title:'};
	warn("WARN: Skip!") && next if $ref->{'Dittman ID'} eq 'NO'; # Old section headers
    warn("WARN: Overwriting \"$title\" ($id vs $panels{$title}{'id'})") if exists($panels{$title});
	$panels{$title}{'id'} = $id;
	$panels{$title}{'title'} = $title;

	# Additional data
	$panels{$title}{'attend'} = $ref->{'Attendance'};
	$panels{$title}{'length'} = $ref->{'Event Length'};
	$panels{$title}{'pref'}{'thursday'} = $ref->{'D_Preference [Thursday]'};
	$panels{$title}{'pref'}{'friday'}   = $ref->{'D_Preference [Friday]'};
	$panels{$title}{'pref'}{'saturday'} = $ref->{'D_Preference [Saturday]'};
	$panels{$title}{'pref'}{'sunday'}   = $ref->{'D_Preference [Sunday]'};
	$panels{$title}{'avail'}{'thursday'} = $ref->{'D_Availability [Thursday]'};
	$panels{$title}{'avail'}{'friday'}   = $ref->{'D_Availability [Friday]'};
	$panels{$title}{'avail'}{'saturday'} = $ref->{'D_Availability [Saturday]'};
	$panels{$title}{'avail'}{'sunday'}   = $ref->{'D_Availability [Sunday]'};

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

my %data; # Complex hash representing the panels already scheduled
my %unscheduled; # Panel names that have cards but are not scheduled

while ( my $row = $schedule->Read ) {
	my $time = $row->{'Room'};
	if ($time =~ /(AM|PM)/ ) { # These are scheduled panels
		for my $room (@rooms) {
			$data{'thursday'}{$room}{$time} = $row->{$room}      if $row->{$room};
			$data{'friday'}{$room}{$time}   = $row->{$room.'_1'} if $row->{$room.'_1'};
			$data{'saturday'}{$room}{$time} = $row->{$room.'_2'} if $row->{$room.'_2'};
			$data{'sunday'}{$room}{$time}   = $row->{$room.'_3'} if $row->{$room.'_3'};
		}
	} else { # These are cards in the parking lot
		for my $column (@rooms, 'Room') {
			for my $section ( qw/_1 _2 _3/ ) {
				my $test = $row->{$column.$section};
				$unscheduled{$test}++ if $test;
			}
		}
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
print scalar(keys %unscheduled), " panel cards yet to be placed on the schedule.\n";

#print Dumper(\%data);
#print Dumper(\%unscheduled);

### Check things

print "==> Checking panels...\n";

for my $day (keys %data) {
	for my $room (keys %{$data{$day}}) {
		for my $time (sort keys %{$data{$day}{$room}}) {
			my $scheduled_panel = $data{$day}{$room}{$time};

			next if $scheduled_panel =~ /^CLOSED$/i;

			my $warnings = 0;
			my @info = ($scheduled_panel);

			# Check: Does the scheduled panel exist in the panel list
			unless ( $panels{$scheduled_panel} ) {
				push(@info, "WARNING: Panel doesn't exist!") unless $panels{$scheduled_panel};
				my $guess = nearest($scheduled_panel);
				push(@info, "WARNING: Possibly a mispelling of \"$guess\"?") if $guess;
				$warnings++;
			}

			my $panel_ref = $panels{$scheduled_panel};

			# Check: panelist conflicts

			my @panelists = keys %{$panel_ref->{'panelists'}};

			if (scalar(@panelists) < 1) {
				push @info, "WARNING: No Panelists!";
				$warnings++;
			} else {
				push @info, "Panelists: " . join(", ", @panelists);
			}

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

			# Check: Have we scheduled this panel more than once?

			my @times = &find_panel_in_data($scheduled_panel, \%data);
			if (scalar(@times) > 1) {
				push(@info, "WARNING: Panel is scheduled ".scalar(@times)." times.");
				$warnings++;
			}

			# Check: panel length

			my $length = $panels{$scheduled_panel}{'length'};

			if (! $length ) {
				push @info, "WARNING: No Panel Length Data!";
				$warnings++;
			} elsif ( $length =~ /SPECIAL TIME/ ) {
				push @info, "Special time/schedule for this panel.";
			} elsif ( $length !~ /^\d+$/ ) {
				push @info, "WARNING: Panel length is odd: \"$length\"?";
				$warnings++;
			} elsif ( $length > 120 or $length < 30 ) {
				push @info, "WARNING: Panel length is odd: \"$length\"?";
				$warnings++;
			} else {
				my $half_hours = int($length/30);
				my $test_time = $time;
				my @time_slots;
				for my $i ( 1 .. $half_hours ) {
					push @time_slots, $test_time;
					$test_time = $next_time{$test_time};
				}
				#print "Time slots: ($length) ", join(",", @time_slots), "\n";
				shift @time_slots; # We're scheduled on our own time, not a conflict
				my $conflicts = 0;
				for my $time_test (@time_slots) {
					if ( defined $data{$day}{$room}{$time_test} ) {
						$conflicts++;
					}
				}
				if ($conflicts > 0) {
					push @info, "WARNING: Panel is too-short on the schedule.";
					$warnings++;
				}
			}

			# Check: panelist time
	
			my $time_code = $dittman_time_code{$time};
			die "Bad time code" unless $time_code;
			my $time_pref = $panels{$scheduled_panel}{'pref'}{$day};
			my $time_avail = $panels{$scheduled_panel}{'avail'}{$day};
			if ( $length =~ /SPECIAL TIME/ ) {
				# Special schedule panels, don't usually have avail data
			} elsif ( !$time_avail ) {
				push @info, "WARNING: No Availability data."
			} elsif ( $time_avail =~ /X/ or $time_avail !~ /$time_code/ ) {
				push @info, "WARNING: Panelist is NOT AVAILABLE at this time. ($time_code vs PREF: $time_pref / AVAIL: $time_avail)";
				$warnings++;
			} elsif ( $time_pref =~ /X/ or $time_pref !~ /$time_code/ ) {
				push @info, "WARNING: Panelist would prefer another time. ($time_code vs PREF: $time_pref / AVAIL: $time_avail)";
				$warnings++;
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

sub find_panel_in_data {
	my $find_name = shift @_;
	my $data = shift @_;

	my @matches = ();

	for my $day (keys %{data}) {
		for my $room (keys %{$data->{$day}}) {
			for my $time (sort keys %{$data->{$day}->{$room}}) {
				if ( $data->{$day}->{$room}->{$time} eq $find_name ) {
					push @matches, "$day $room $time";
				}
			}
		}
	}

	return @matches;
}