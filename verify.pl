#!/usr/bin/env perl

use Data::Dumper qw/Dumper/;
use String::Similarity;
use Text::TabFile;
use strict;

=head1 Check the schedule against the panel list

 * Does the scheduled panel exist in the panel list?
 * Are all panels in the panel list on the schedule?
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
		}
	} else {
		warn("WARN: $title ($id) has no host\n");
	}

	if ( $ref->{'Special Guests'} ) {
		for my $host ( split /\s*[,;\&]\s*/, $ref->{'Special Guests'} ) {
			$panels{$title}{'panelists'}{$host}++;
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

my %scheduled_panels; # Simple hash of panels on the schedule
my %panelists; # Complex hash used to check for panelist double-bookings
my %simple_panelists; # Simple hash to count panels per panelist
my %warnings; # Complex hash of problems

for my $day (keys %data) {
	for my $room (keys %{$data{$day}}) {
		for my $time (sort keys %{$data{$day}{$room}}) {
			my $scheduled_panel = $data{$day}{$room}{$time};
			next if $scheduled_panel =~ /^CLOSED$/i;
			$scheduled_panels{$scheduled_panel}++;

			# Check: Does the scheduled panel exist in the panel list
			unless ( defined $panels{$scheduled_panel} ) {
				$warnings{'NOT_IN_LIST'}{$scheduled_panel}++;
				my $guess = nearest($scheduled_panel);
				$warnings{'NOT_IN_LIST'}{$scheduled_panel} = $guess if $guess;
			}

			my $panel_ref = $panels{$scheduled_panel};

			# Check: Have we scheduled this panel more than once?

			my @times = &find_panel_in_data($scheduled_panel, \%data);
			if (scalar(@times) > 1) {
				$warnings{'MULTIPLE_TIMES'}{$scheduled_panel} = scalar(@times);
			}

			# Check: panel length / conflicts with a following panel

			my $length = $panels{$scheduled_panel}{'length'};
			my @panel_times = ( $time );

			if (! $length ) {
				$warnings{'TIME_ERROR'}{$scheduled_panel} = "No panel length data.";
			} elsif ( $length =~ /SPECIAL TIME/ ) {
				$warnings{'TIME_ERROR'}{$scheduled_panel} = "Panel is 'special' and no time checks performed";
			} elsif ( $length !~ /^\d+$/ ) {
				$warnings{'TIME_ERROR'}{$scheduled_panel} = "Can't parse length: \"$length\"?";
			} elsif ( $length > 120 or $length < 30 ) {
				$warnings{'TIME_ERROR'}{$scheduled_panel} = "Too big or too small: \"$length minutes\"?";
			} else {
				my $half_hours = int($length/30);
				my $test_time = $time;
				my @time_slots;
				for my $i ( 1 .. $half_hours ) {
					push @time_slots, $test_time;
					$test_time = $next_time{$test_time};
				}
				@panel_times = @time_slots; # Save the full run of times to check for panelist conflicts
				shift @time_slots; # We're scheduled on our own time, not a conflict
				my $conflicts = 0;
				for my $time_test (@time_slots) {
					if ( defined $data{$day}{$room}{$time_test} ) {
						$conflicts++;
					}
				}
				if ($conflicts > 0) {
					$warnings{'TIME_ERROR'}{$scheduled_panel} = "Panel is too short on the schedule";
				}
			}

			# Check: missing panelists & store data for panelist-conflict check

			my @panelists = keys %{$panel_ref->{'panelists'}};

			if (scalar(@panelists) < 1) {
				$warnings{'NO_PANELISTS'}{$scheduled_panel}++;
			}

			for my $panelist (@panelists) {
				$simple_panelists{$panelist}{$scheduled_panel}++;
				for my $time (@panel_times) {
					$panelists{$panelist}{$day}{$time}{$scheduled_panel}++;
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
				$warnings{'AVAIL_NO_DATA'}{$scheduled_panel}++;
			} elsif ( $time_avail =~ /X/ or $time_avail !~ /$time_code/ ) {
				$warnings{'AVAIL_BAD'} {$scheduled_panel} = "$time_code vs PREF: $time_pref / AVAIL: $time_avail";
			} elsif ( $time_pref =~ /X/ or $time_pref !~ /$time_code/ ) {
				$warnings{'AVAIL_PREF'}{$scheduled_panel} = "$time_code vs PREF: $time_pref / AVAIL: $time_avail";
			}

		}
	}
}

# Check for panelist conflicts

for my $panelist (keys %panelists) {
	for my $day ( keys %{$panelists{$panelist}}) {
		for my $time ( keys %{$panelists{$panelist}{$day}}) {
			my @panels = sort keys %{$panelists{$panelist}{$day}{$time}};
			if ( scalar(@panels) > 1) {
				$warnings{'DOUBLE_BOOK'}{$panelist}{"$day $time"} = \@panels;
			}
		}
	}
}

# Check that all panels in the list are on the schedule
for my $panel (keys %panels) {
	$warnings{'NOT_IN_SCHEDULE'}{$panel}++ unless defined $scheduled_panels{$panel};
}

# Print out the report

my $line = ('=' x 80) . "\n";

print $line, "Panels on the schedule, but not in the list-of-panels:\n", $line, "\n";
print "\t", (join "\n\t", sort keys %{$warnings{'NOT_IN_LIST'}}), "\n\n";

print $line, "Panels on the list-of-panels, but not in the schedule:\n", $line, "\n";
print "\t", (join "\n\t", sort keys %{$warnings{'NOT_IN_SCHEDULE'}}), "\n\n";

print $line, "Panels scheduled multiple times:\n", $line, "\n";
print "\t", (join "\n\t", sort keys %{$warnings{'MULTIPLE_TIMES'}}), "\n\n";

print $line, "Panels lacking panelist info:\n", $line, "\n";
print "\t", (join "\n\t", sort keys %{$warnings{'NO_PANELISTS'}}), "\n\n";

print $line, "Panels lacking availability info:\n", $line, "\n";
print "\t", (join "\n\t", sort keys %{$warnings{'AVAIL_NO_DATA'}}), "\n\n";

print $line, "Panelists are double booked:\n", $line, "\n";
for my $panelist ( sort keys %{$warnings{'DOUBLE_BOOK'}} ) {
	for my $when ( sort keys %{$warnings{'DOUBLE_BOOK'}{$panelist}} ) {
		my @panels = @{$warnings{'DOUBLE_BOOK'}{$panelist}{$when}};
		print "\t$panelist is double-booked at $when on: '", join("', '", @panels), "'\n";
	}
}
print "\n";

print $line, "Panels with length/time issues:\n", $line, "\n";
for my $panel ( sort keys %{$warnings{'TIME_ERROR'}} ) {
	print "\t'$panel' : $warnings{'TIME_ERROR'}{$panel}\n";
}
print "\n";

print $line, "Panelists are unavailable:\n", $line, "\n";
for my $panel ( sort keys %{$warnings{'AVAIL_BAD'}} ) {
	print "\t'$panel' : $warnings{'AVAIL_BAD'}{$panel}\n";
}
print "\n";

print $line, "Panelists would prefer a different time:\n", $line, "\n";
for my $panel ( sort keys %{$warnings{'AVAIL_PREF'}} ) {
	print "\t'$panel' : $warnings{'AVAIL_PREF'}{$panel}\n";
}
print "\n";

print $line, "Panelists with more than 5 panels:\n", $line, "\n";
for my $panelist ( sort keys %simple_panelists) {
	my $count = scalar(keys %{$simple_panelists{$panelist}});
	if ( $count > 4 ) {
		print "\t$panelist : $count panels\n\n";
		map { print "\t\t$_\n"; } sort keys %{$simple_panelists{$panelist}};
		print "\n";
	}
}
print "\n";


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