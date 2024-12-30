all: panels.tab schedule.tab

schedule.tab:
	tail +7 Master\ Schedule\ Document-\ F2\ 2025\ -\ Schedule.tsv > $@

panels.tab:
	tail +2 "Master Schedule Document- F2 2025 - Panels To Schedule - from Dittman's Sheet.tsv" > $@
