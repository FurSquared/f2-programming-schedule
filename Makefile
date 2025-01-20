all: schedule.tab

clean:
	rm -v build.tab panels.tab schedule.tab session?.json || true

realclean superclean: clean
	rm -v *.tsv || true

pretalx-add: Master\ Schedule\ Document-\ F2\ 2025\ -\ Additional\ Panels.tsv
	tail +23 'Master Schedule Document- F2 2025 - Additional Panels.tsv' > pretalx-to-add.tab
	./pretalx-create-events.py -i pretalx-to-add.tab | tee pretalx-to-add.tab.out

build.tab: schedule.tab
	./pretalx-build-loadfile.pl > $@

schedule.tab:
	tail +7 Master\ Schedule\ Document-\ F2\ 2025\ -\ SCHEDULE.tsv | head -n1 > $@
	tail +10 Master\ Schedule\ Document-\ F2\ 2025\ -\ SCHEDULE.tsv >> $@

panels.tab:
	tail +2 "Master Schedule Document- F2 2025 - Panels To Schedule - Dittman.tsv" > $@

session1.json:
	curl -X GET 'https://schedule.fursquared.com/api/events/f2-2025/submissions/' -H "Authorization: Token ${TOKEN}" | tee session1.json | jq .
	curl -X GET 'https://schedule.fursquared.com/api/events/f2-2025/submissions/?limit=25&offset=25' -H "Authorization: Token ${TOKEN}" | tee session2.json | jq .
	curl -X GET 'https://schedule.fursquared.com/api/events/f2-2025/submissions/?limit=25&offset=50' -H "Authorization: Token ${TOKEN}" | tee session3.json | jq .
	curl -X GET 'https://schedule.fursquared.com/api/events/f2-2025/submissions/?limit=25&offset=75' -H "Authorization: Token ${TOKEN}" | tee session4.json | jq .
	curl -X GET 'https://schedule.fursquared.com/api/events/f2-2025/submissions/?limit=25&offset=100' -H "Authorization: Token ${TOKEN}" | tee session5.json | jq .
	curl -X GET 'https://schedule.fursquared.com/api/events/f2-2025/submissions/?limit=25&offset=125' -H "Authorization: Token ${TOKEN}" | tee session6.json | jq .
