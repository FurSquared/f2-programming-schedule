#!/usr/bin/env perl

# Figure out the dittman ID for the main panel list and put it in order

use Data::Dumper qw/Dumper/;
use Text::TabFile;
use strict;

# Crosswalking the data on the Dittman ID
# Outputting content that can be pasted in the master panel list (copied from the Dittman tab)

# Note: the Ditttman ID is a 4-digit numeric string. Leading zeros matter.

# Slurp up the Dittman tab

my $ref = new Text::TabFile ('panels.tab', 1);

my %dittman; # Complex hash of Dittman data keyed by ID
while ( my $line = $ref->Read ) {
	$dittman{$line->{'Panel ID'}} = $line;
}

# What we're copying

my @cols_to_copy = ('Room Setup', 'Availability [Thursday]', 'Availability [Friday]',
	'Availability [Saturday]', 'Availability [Sunday]', 'Preference [Thursday]',
	'Preference [Friday]', 'Preference [Saturday]', 'Preference [Sunday]', 'Attendance',
	'Do you intend to collect money for the charity at this event?', 'Audio', 'Projector',
	'Power Strip', 'Volunteer Assistants','Other');
my $col_count = scalar(@cols_to_copy);

# Process the panel tab and build output

$ref = new Text::TabFile ('Master Schedule Document- F2 2025 - Panels To Schedule.tsv', 1);

print join("\t", map {"D_$_"} @cols_to_copy), "\n";

while ( my $line = $ref->Read ) {
	my $did = $line->{'Dittman ID'};
	print join("\t", map {$dittman{$did}{$_} ? $dittman{$did}{$_} : undef} @cols_to_copy ), "\n";
}