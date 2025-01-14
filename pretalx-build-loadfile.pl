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

### Read the schedule

my $schedule = new Text::TabFile ('schedule.tab', 1);
my @header = $schedule->fields;

my @rooms = qw/Crystal Kilbourn MacArthur Miller Mitchell Other Pabst
               S201 Schlitz Usinger Walker Wright/;

while ( my $row = $schedule->Read ) {
	my $time = $row->{'Room'};
	if ($time =~ /(AM|PM)/ ) { # These are scheduled panels
		for my $room (@rooms) {
			push @{$panels{$row->{$room}}{'when'}}, ['thursday', $time, $room] if $row->{$room};
			push @{$panels{$row->{$room.'_1'}}{'when'}}, ['friday', $time, $room] if $row->{$room.'_1'};
			push @{$panels{$row->{$room.'_2'}}{'when'}}, ['saturday', $time, $room] if $row->{$room.'_2'};
			push @{$panels{$row->{$room.'_3'}}{'when'}}, ['sunday', $time, $room] if $row->{$room.'_3'};
		}
	}
}

### Build the output file

my @heads = qw/id title length desc category/;

print tl(@heads, 'day', 'time', 'room');
for my $panel ( sort keys %panels ) {
	my $p = $panels{$panel};
	print tl((map {$p->{$_}} @heads), (defined $p->{'when'} ? @{$p->{'when'}->[0]} : ('','','')));
}