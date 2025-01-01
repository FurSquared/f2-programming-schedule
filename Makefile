all: panels.tab schedule.tab

clean:
	rm -v panels.tab schedule.tab || true

schedule.tab:
	tail +7 Master\ Schedule\ Document-\ F2\ 2025\ -\ Schedule.tsv | head -n1 > $@
	tail +10 Master\ Schedule\ Document-\ F2\ 2025\ -\ Schedule.tsv >> $@

panels.tab:
	tail +2 "Master Schedule Document- F2 2025 - Panels To Schedule - Dittman.tsv" > $@
