#!/usr/bin/env python3
""" Room Reports - Schedule for each room
"""

import sys

from datetime import datetime, timedelta
from pprint import pprint
from time import sleep

import argparse
import csv

def main():
    """The main program -- do I really need to docstring this?"""
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input", action='append', help="Input tabfile", required=True)
    args = parser.parse_args()

    schedule = {}

    for input_file in args.input:
        with open(input_file, "r", encoding="utf-8") as file:
            reader = csv.DictReader(file, delimiter="\t")
            for row in reader:
                pt_id = row["id"]
                title = row["title"]
                category = row["category"]
                room = row["room"]

                # Time math is fun
                length = row["length"]
                if length and length.isnumeric() is False:
                    length = ""
                day = row["day"]
                time = row["time"]

                start = None
                end = None

                if day and time and length:
                    if row["day"] == "thursday":
                        start = datetime.strptime(f'2026-02-05 {time}', "%Y-%m-%d %I:%M %p")
                    if row["day"] == "friday":
                        start = datetime.strptime(f'2026-02-06 {time}', "%Y-%m-%d %I:%M %p")
                    if row["day"] == "saturday":
                        start = datetime.strptime(f'2026-02-07 {time}', "%Y-%m-%d %I:%M %p")
                    if row["day"] == "sunday":
                        start = datetime.strptime(f'2026-02-08 {time}', "%Y-%m-%d %I:%M %p")

                    if time in ['12:00 AM', '12:30 AM', '1:00 AM', '1:30 AM']:
                        start = start + timedelta(minutes=1440)

                    end = start + timedelta(minutes=int(length))

                    hour_start = start.strftime("%H")
                    start = start.strftime("%-I:%M %p")
                    end = end.strftime("%-I:%M %p")

                if room not in schedule:
                    schedule[room] = {}
                if day not in schedule[room]:
                    schedule[room][day] = {}
                schedule[room][day][hour_start] = [ start, end, title ]

    #pprint(schedule)

    for room, info in sorted(schedule.items()):
        for day in ['thursday', 'friday', 'saturday', 'sunday']:
            if day in info:
                print(f"\n{room} - {day}\n")
                for hour, panel in sorted(info[day].items()):
                    print(f"{panel[0]}-{panel[1]} {panel[2]}")


if __name__ == "__main__":
    main()
