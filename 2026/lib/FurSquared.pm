#!/usr/bin/env perl

use Text::TabFile qw/tl/;
use strict;

### Config

my %ignore_these_panels = map {$_=>1} (
	'CLOSED', 'Not Available',
        'Hotel Cleanup', 'Hotel Setup', 'Hotel Setup Time',
	'DJ Seating', 'Set to DJ', 'Dance Seating', 'Set to Dance', 'Set to Theater', 'Theater Seating'
);

my %fix_name = (
  'Aetus' => qr/(hal)?\s*aetus/i,
  'Alkali Bismuth' => qr/alkali(\s*bismuth)?/i,
  'Boozy Badger' => qr/boozy(\s*badger)?/i,
  'Cornel the Otter' => qr/cornel(\s*(the\s+)?otter)?$/i,
  'keyotter' => qr/key\s*otter/i,
  'Pepper Coyote' => qr/pepper(\s*coyote)?/i,
  'Rhubarb' => qr/rhubarb\s*nido/i,
  'Status Ferret' => qr/status(\s*ferret)?/i,
);

my @skip_name = (
  qr/^N\/?A$/i,
  qr/^no(ne)?$/i,
  qr/^TB[AD]$/,
  qr/^and more$/,
  qr/\d\s?-\s?\d special guests/i,
);

### Methods

sub parse_panels {
  my $file = shift @_;
  my $panels = new Text::TabFile ($file, 1);

  my %panels; # complex hash of panel data, keyed by name
  my %panelists; # counting hash of panelist names

  while ( my $ref = $panels->Read ) {
    my $id = $ref->{'ID'};
    my $title = $ref->{'Panel / Event Title:'};

    $panels{$title}{'id'} = $id;
    $panels{$title}{'title'} = $title;

    # Additional data
    $panels{$title}{'attend'} = $ref->{'Attendance'};
    $panels{$title}{'desc'} = $ref->{'Event / Panel Description:'};
    $panels{$title}{'category'} = $ref->{'Category:'};
    $panels{$title}{'length'} = $ref->{'Event Length'};

    $panels{$title}{'pref'}{'thursday'} = avail_summary($ref->{'Preference [Thursday]'});
    $panels{$title}{'pref'}{'friday'}   = avail_summary($ref->{'Preference [Friday]'});
    $panels{$title}{'pref'}{'saturday'} = avail_summary($ref->{'Preference [Saturday]'});
    $panels{$title}{'pref'}{'sunday'}   = avail_summary($ref->{'Preference [Sunday]'});
    $panels{$title}{'avail'}{'thursday'} = avail_summary($ref->{'Availability [Thursday]'});
    $panels{$title}{'avail'}{'friday'}   = avail_summary($ref->{'Availability [Friday]'});
    $panels{$title}{'avail'}{'saturday'} = avail_summary($ref->{'Availability [Saturday]'});
    $panels{$title}{'avail'}{'sunday'}   = avail_summary($ref->{'Availability [Sunday]'});

    # Panelists

    my @hosts = &extract_names($ref->{'Hosted by:'});
    my @guests = &extract_names($ref->{'Special Guests'});

    $panels{$title}{'hosts'} = join(', ', @hosts);
    $panels{$title}{'guests'} = join(', ', @guests);

    for my $name (@hosts, @guests) {
      $panels{$title}{'panelists'}{$name}++;
      $panelists{$name}{$title}++;
    }

    # Input cleanup
    $panels{$title}{'length'} =~ s/\s+minutes\s*//ig;
  }

  return (\%panels, \%panelists)
}


sub add_schedule_to_panels {
  my $file = shift @_;
  my %panels = %{shift @_};
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
  return \%panels;
}

sub extract_names {
  my $raw = shift @_;
  my @out;
  for my $candidate ( split /\s*[,;&]\s*/, $raw ) {
    for my $corrected_name ( keys %fix_name ) {
      for my $skip (@skip_name) {
        if ( $candidate =~ /$skip/ ) {
          warn "NAMES: Ignoring \"$candidate\"";
          $candidate = undef;
        }
      }
      if ($candidate =~ /$fix_name{$corrected_name}/) {
        warn "NAMES: Correcting \"$candidate\" to \"$corrected_name\"" unless $candidate eq $corrected_name;
        $candidate = $corrected_name;
        last;
      }
      if ( $candidate =~ /^(and|hosts?:|hosted by:) (.+)$/i ) {
        warn "NAMES: Correcting \"$candidate\" to \"$2\"";
        $candidate = $2;
      }
    }
    push @out, $candidate if $candidate;
  }
  return @out
}

sub avail_summary {
  my $raw = shift @_;
  return 'X' if $raw =~ /Not Available/;
  return 'ABCD' if $raw =~ /Anytime/;
  my $out;
  $out .= 'A' if $raw =~ /Morning/;
  $out .= 'B' if $raw =~ /Afternoon/;
  $out .= 'C' if $raw =~ /Evening/;
  $out .= 'D' if $raw =~ /Late Night/;
  return $out if length($out) > 0;
  return '?';
}

