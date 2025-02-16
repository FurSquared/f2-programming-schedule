all: schedule.tab

clean:
	rm -v build.tab panels.tab schedule.tab session?.json || true

realclean superclean: clean
	rm -v *.tsv || true

pretalx-add: additional-panels.tab
	./pretalx-create-events.py -i $@ | tee $@.out

additional-panels.tab: Master\ Schedule\ Document-\ F2\ 2025\ -\ Additional\ Panels.tsv
	tail +23 'Master Schedule Document- F2 2025 - Additional Panels.tsv' > additional-panels.tab

build.tab: schedule.tab
	./pretalx-build-loadfile.pl > $@

schedule.tab: Master\ Schedule\ Document-\ F2\ 2025\ -\ FOR\ PRINT-Pocket\ Schedule.tsv
	tail +3 Master\ Schedule\ Document-\ F2\ 2025\ -\ FOR\ PRINT-Pocket\ Schedule.tsv | head -n1 | sed -e 's/Wright B & C Board Gaming		/Wright B	Wright C	/g' -e 's/ Board Gaming//g' -e 's/ Video Gaming//g' -e 's/		/	Other	/g' > $@
	tail +4 Master\ Schedule\ Document-\ F2\ 2025\ -\ FOR\ PRINT-Pocket\ Schedule.tsv >> $@

panels.tab:
	tail +2 "Master Schedule Document- F2 2025 - Panels To Schedule - Dittman.tsv" > $@

session1.json:
	curl -X GET 'https://schedule.fursquared.com/api/events/f2-2025/submissions/' -H "Authorization: Token ${TOKEN}" | tee session1.json | jq .
	curl -X GET 'https://schedule.fursquared.com/api/events/f2-2025/submissions/?limit=25&offset=25' -H "Authorization: Token ${TOKEN}" | tee session2.json | jq .
	curl -X GET 'https://schedule.fursquared.com/api/events/f2-2025/submissions/?limit=25&offset=50' -H "Authorization: Token ${TOKEN}" | tee session3.json | jq .
	curl -X GET 'https://schedule.fursquared.com/api/events/f2-2025/submissions/?limit=25&offset=75' -H "Authorization: Token ${TOKEN}" | tee session4.json | jq .
	curl -X GET 'https://schedule.fursquared.com/api/events/f2-2025/submissions/?limit=25&offset=100' -H "Authorization: Token ${TOKEN}" | tee session5.json | jq .
	curl -X GET 'https://schedule.fursquared.com/api/events/f2-2025/submissions/?limit=25&offset=125' -H "Authorization: Token ${TOKEN}" | tee session6.json | jq .

transposed.xlsx: build.tab additional-panels.tab
	./transposed.py -i build.tab -a additional-panels.tab

room-report.txt:
	./report-rooms.py -i build.tab -i additional-panels.tab > $@
