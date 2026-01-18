all: build-programming.tsv build-tabletop.tsv build-video.tsv report-rooms.txt report-verify.txt

clean:
	rm -v report-*.txt build*.t?? panels.tab schedule.tab || true

# Also removing source files
realclean superclean: clean
	rm -v *.tsv || true

# Build is a basic loader file that shows the full schedule that
# other scripts and systems can use.
build.tab: panels.tab schedule.tab
	./create-loadfile.pl > $@
build-programming.tsv: build.tab
	head -1 build.tab > $@
	tail +2 build.tab | grep -v "Hilton Honors Lounge" | grep -v "Monarch Lounge" | grep -v "Wright B+C" >> $@
	tail +2 additional.tab >> $@
build-tabletop.tsv: build.tab
	head -1 build.tab > $@
	tail +2 build.tab | grep "Hilton Honors Lounge" >> $@
	tail +2 build.tab | grep "Monarch Lounge" >> $@
build-video.tsv: build.tab
	head -1 build.tab > $@
	tail +2 build.tab | grep "Wright B+C" >> $@

# Pre-processing - removing leading-blank lines from the Schedule tsv
panels.tab: F2\ 2026\ Schedule\ MASTER\ -\ Panels\ to\ Schedule.tsv
	cat "F2 2026 Schedule MASTER - Panels to Schedule.tsv" | grep -v "^			" > $@

panels-removed.tab: F2\ 2026\ Schedule\ MASTER\ -\ Panels\ removed_rejected.tsv
	cat 'F2 2026 Schedule MASTER - Panels removed_rejected.tsv' | grep -v "^			" > $@

# Pre-processing: A header-cleaned version of the Schedule tsv so the first
# few lines of room detail are removed.
schedule.tab: F2\ 2026\ Schedule\ MASTER\ -\ CURRENT\ SCHEDULE.tsv
	tail +7 F2\ 2026\ Schedule\ MASTER\ -\ CURRENT\ SCHEDULE.tsv | head -n1 > $@
	tail +10 F2\ 2026\ Schedule\ MASTER\ -\ CURRENT\ SCHEDULE.tsv | perl -ne '!/^[\t\s]+$$/ && print' >> $@

# Print out the "cards" for the panel. That is, short-hand short-hand text
# that shows the availability of the panelist and their preferences. This
# is put in the cell-notes on the "card" in master schedule spreadsheet
report-cards.txt: panels.tab
	./generate-cards.pl > $@

# Check if the IDs are contiguous. Did we drop something?
report-ids.txt: panels.tab panels-removed.tab
	./check-ids.pl panels.tab panels-removed.tab > $@

# A HTML file of panel info, useful to hand to the conbook
report-descriptions.html: panels.tab
	./export-descriptions.pl > $@

# A breakdown of events by room
report-rooms.txt: build.tab
	./report-rooms.py -i build.tab > $@

# The verification report: look for trouble on the schedule.
report-verify.txt: schedule.tab panels.tab
	./verify.pl > $@

# Pivot the schedule to the side
transposed.xlsx: build.tab
	./transposed.py -i build.tab
