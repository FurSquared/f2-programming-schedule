#!/usr/bin/env perl

use Data::Dumper qw/Dumper/;
use String::Similarity;
use Text::TabFile qw/tl/;
use strict;

use lib 'lib';
use FurSquared qw/parse_panels add_schedule_to_panels/;

=head1 Build a loadfile for pretalx

Using schedule.tab and the Panels to schedule file, create a loadfile for pretalx

=cut

### Config

my $panel_list_file = 'panels.tab';
my $schedule_file = 'schedule.tab';

### Read the panel list

my @pnp = parse_panels($panel_list_file);
my %panels = %{$pnp[0]};
my %panelists = %{$pnp[1]};


my $ret = add_schedule_to_panels($schedule_file, \%panels);
%panels = %{$ret};

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
