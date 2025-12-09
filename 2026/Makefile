all: schedule.tab

clean:
	rm -v build.tab panels.tab schedule.tab || true

realclean superclean: clean
	rm -v *.tsv || true

build.tab: panels.tab schedule.tab
	./create-loadfile.pl > $@

schedule.tab: F2\ 2026\ Schedule\ MASTER\ -\ Schedule.tsv
	tail +7 F2\ 2026\ Schedule\ MASTER\ -\ Schedule.tsv | head -n1 > $@
	tail +10 F2\ 2026\ Schedule\ MASTER\ -\ Schedule.tsv >> $@

panels.tab:
	cat "F2 2026 Schedule MASTER - Panels to Schedule.tsv" | grep -v "^			" > $@
