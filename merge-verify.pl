#!/usr/bin/env perl

# Figure out the dittman ID for the main panel list and put it in order

use Data::Dumper qw/Dumper/;
use Text::TabFile;
use strict;

# Crosswalking the data on the Dittman ID
# Comparing content for differences

# Note: the Dittman ID is a 4-digit numeric string. Leading zeros matter.

# Slurp up the Dittman tab

my $ref = new Text::TabFile ('panels.tab', 1);

my %dittman; # Complex hash of Dittman data keyed by ID
while ( my $line = $ref->Read ) {
	$dittman{$line->{'Panel ID'}} = $line;
}

# Slurp up the master tab

$ref = new Text::TabFile ('Master Schedule Document- F2 2025 - Panels To Schedule.tsv', 1);

my %master;
while ( my $line = $ref->Read ) {
	my $did = $line->{'Dittman ID'};
	next unless $did;
	$master{$did} = $line;
}

### Compare things

print "### Title Check:\n\n";

for my $did ( keys %master ) {
	&compare_fields($did, 'Panel / Event Title:', 'Panel / Event Title:');
}

print "### Description Check:\n\n";

for my $did ( keys %master ) {
	&compare_fields($did, 'Event / Panel Description:', 'Event / Panel Description:');
}

### Subs

sub compare_fields {
	my $did    = shift @_ || die;
	my $m_name = shift @_ || die;
	my $d_name = shift @_ || die;
	my $m_data = $master{$did}{$m_name};
	my $d_data = $dittman{$did}{$d_name};
	print "Master  : $m_data\nDittman : $d_data\n\n" unless $m_data eq $d_data;
}