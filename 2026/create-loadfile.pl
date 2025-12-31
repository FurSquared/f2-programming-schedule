#!/usr/bin/env perl

use Data::Dumper qw/Dumper/;
use String::Similarity;
use Text::TabFile qw/tl/;
use strict;

=head1 Build a loadfile for pretalx

Using schedule.tab and the Panels to schedule file, create a loadfile for pretalx

=cut

### Config

my $panel_list_file = 'panels.tab';
my $schedule_file = 'schedule.tab';

my %ignore_these_panels = map {$_=>1} (
	'CLOSED', 'Not Available',
        'Hotel Cleanup', 'Hotel Setup', 'Hotel Setup Time',
	'DJ Seating', 'Set to DJ', 'Dance Seating', 'Set to Dance', 'Set to Theater', 'Theater Seating'
);

### Read the panel list

my $panels = new Text::TabFile ($panel_list_file, 1);

my %panels; # complex hash of panel data, keyed by name
my %panelists; # counting hash of panelist names

while ( my $ref = $panels->Read ) {
	my $id = $ref->{'ID'};
	my $title = $ref->{'Panel / Event Title:'};

	$panels{$title}{'id'} = $id;
	$panels{$title}{'title'} = $title;

	# Additional data
	$panels{$title}{'length'} = $ref->{'Event Length'};
	$panels{$title}{'desc'} = $ref->{'Event / Panel Description:'};
	$panels{$title}{'category'} = $ref->{'Category:'};

	$panels{$title}{'hosts'} = $ref->{'Hosted by:'};
	$panels{$title}{'guests'} = $ref->{'Special Guests'};

	# Panelists
	if ( $ref->{'Hosted by:'} ) {
		for my $host ( split /\s*[,;\&]\s*/, $ref->{'Hosted by:'} ) {
			$panels{$title}{'panelists'}{$host}++;
			$panelists{$host}{$title}++;
		}
	}

	if ( $ref->{'Special Guests'} ) {
		for my $host ( split /\s*[,;\&]\s*/, $ref->{'Special Guests'} ) {
			$panels{$title}{'panelists'}{$host}++;
			$panelists{$host}{$title}++;
		}
	}

	# Input cleanup
	$panels{$title}{'length'} =~ s/\s+minutes\s*//ig;
}

### Append times time from schedule

my $schedule = new Text::TabFile ('schedule.tab', 1);

my @days = qw/thursday friday saturday sunday/;

my %next_day = (
	'thursday' => 'friday',
	'friday' => 'saturday',
	'saturday' => 'sunday',
);
my %next_day_hours = map {$_ => 1} ('12:00 AM', '12:30 AM', '1:00 AM', '1:30 AM');

my %headers;
my $day_position = -1;
for my $header ($schedule->fields) {
	if ( $header =~ /^Room/ ) {
		$day_position++;
	} else {
		push @{ $headers{$days[$day_position]} }, $header;
	}
}

while ( my $row = $schedule->Read ) {
	my $time = $row->{'Room'};
	if ($time =~ /(AM|PM)/ ) { # These are scheduled panels
		for my $day (@days) {
			for my $key (@{$headers{$day}}) {
				my $room = $key;
				$room =~ s/_\d+$//;
				if ( $row->{$key} ) {
					#print STDERR "$room\n";
					my $panel = $row->{$key};

					next if $ignore_these_panels{$panel};

					if ( $room eq 'Other' ) {
						if ( $panel =~ /(.+) \((.+)\)/ ) {
          						$panel = $1;
          						$room = $2;
						} else {
							warn "Other room fail. ($key/$time/$panel)";
							next;
						}
					}
					if ( not defined $panels{$panel} ) {
						warn("Scheduled '$panel' is not in the panel list.")
					} else {
						my $room_rewrite = $room;
						$room_rewrite = 'Crystal ballroom' if $room =~ /Crystal/;
						$room_rewrite = 'Empire ballroom' if $room =~ /Empire/;
                                                $room_rewrite = 'Hilton Honors Lounge' if $room =~ /Honors L/;

						# We display early-morning hours on previous day in the spreadsheet.
						my $actual_day = $day; 
						if ( $next_day_hours{$time} ) {
							$actual_day = $next_day{$day};
							die "Next day lookup failed for: $panel ($day)" unless $next_day{$day};
						}

						push @{$panels{$panel}{'when'}}, [$actual_day, $time, $room_rewrite]
					}
				}
			}
		}
	}
}

### Build the output file

my @heads = qw/length category id title hosts guests desc/;

print tl('day', 'time', 'room', @heads);
for my $panel ( sort keys %panels ) {
	my $p = $panels{$panel};
	my @when = ('', '', '');
	if ( defined $p->{'when'} ) {
		my @times = @{$p->{'when'}}; # Panel can be multiple times
		@when = @{shift @times}; # Just use the first time
	        print tl(@when, (map {$p->{$_}} @heads));

                my $count = 0;
		for my $additional_time (@times) {
			warn "[$panel] is duped!";
			my @out = (@$additional_time, (map {$p->{$_}} @heads));
                        $out[5] = $p->{'id'} .'-'. ++$count;
			print tl(@out);
                }

	} else {
		warn "Skipping $p->{'title'} as it is unscheduled";
		#print tl(@when, (map {$p->{$_}} @heads));
	}
}
