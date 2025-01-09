# f2-programming-schedule

Utilities around building and validating the schedule

Perl is used. You will need the following CPAN libraries as well:

* Text::TabFile
* String::Similarity

# Download the data

These files do their work using tab-separated exports from the schedule Google sheet.

Export the relevant files:

* 'Master Schedule Document- F2 2025 - Panels To Schedule - Dittman.tsv'
* 'Master Schedule Document- F2 2025 - Panels To Schedule.tsv'
* 'Master Schedule Document- F2 2025 - Schedule.tsv'

Copy them locally and run the make process to fix header issues:

```
make clean all
```

This will produce two additional files:

* panels.tab
* schedule.tab

You can then run any of the scripts below:

# Verify panel content

```
./verify.pl
```

This will do sanity checks:
* Double scheduling of panels
* Double scheduling of panelists
* Scheduled panels not in the approved panel list
* Panels on the list not in the schedule

# Merge utilities

These were used to merge the two schedule tabs.

* **./merge-map-dittman-ids.pl** - Generate a list of Dittman IDs in the order of the master panel tab so they can be pasted into it. (Crosswalking the two sheets)
* **./merge-panel-tabs.pl > additional-data.tab** - Generate output of Dittman tab data to put append to the master panel tab so they can be merged.
* **./merge-verify.pl** - Compare the Master and Dittman schedule tabs to see differences

# Pretalx utilities

These depend on a credentials file of "credentials.txt" with username and password like:

```
username: mylogin@email.com
password: mypassword
```

* **pretalx-create-events.py** - Reads the panel list and creates basic entries in pretalx.
* **./pretalx-ids-for-schedule.pl > xwalk.tab** - Reads the session?.json files to build a pretlax ID xwalk based on panel name
