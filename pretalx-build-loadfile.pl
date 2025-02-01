#!/usr/bin/env perl

use Data::Dumper qw/Dumper/;
use String::Similarity;
use Text::TabFile qw/tl/;
use strict;

=head1 Build a loadfile for pretalx

Using schedule.tab and the Panels to schedule file, create a loadfile for pretalx

=cut

### Config

my $panel_list_file = 'Master Schedule Document- F2 2025 - Panels To Schedule.tsv';
my $schedule_file = 'schedule.tab';

### Read the panel list

my $panels = new Text::TabFile ($panel_list_file, 1);

my %panels; # complex hash of panel data, keyed by name
my %panelists; # counting hash of panelist names

while ( my $ref = $panels->Read ) {
	my $id = $ref->{'Pretalx ID'};
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

my %headers;
my $day_position = -1;
for my $header ($schedule->fields) {
	if ( $header =~ /^Room/ ) {
		$day_position++;
	} else {
		push @{ $headers{$days[$day_position]} }, $header;
	}
}

#print Dumper(\%headers);
#exit;

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
					if ( $room eq 'Other' ) {
						$panel =~ /(.+) \((.+)\)/ or die "Other room fail.";
          				$panel = $1;
          				$room = $2;
					}
					if ( not defined $panels{$panel} ) {
						warn("Scheduled '$panel' is not in the panel list.")
					} else {
						my $room_rewrite = $room;
						$room_rewrite = 'Crystal' if $room =~ /Crystal/;
						$room_rewrite = 'Empire' if $room =~ /Empire/;
						push @{$panels{$panel}{'when'}}, [$day, $time, $room_rewrite]
					}
				}
			}
		}
	}
}

#print Dumper(\%panels);
#exit;

### Build the output file

my @heads = qw/length category id title hosts guests desc/;

print tl('day', 'time', 'room', @heads);
for my $panel ( sort keys %panels ) {
	my $p = $panels{$panel};
	my @when = ('', '', '');
	if ( defined $p->{'when'} ) {
		my @times = @{$p->{'when'}}; # Panel can be multiple times
		@when = @{$times[0]}; # Just use the first time
	}
	print tl(@when, (map {$p->{$_}} @heads));
}