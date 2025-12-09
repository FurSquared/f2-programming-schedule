#!/usr/bin/env python 

import argparse
import csv
import xlsxwriter

from datetime import datetime, timedelta
from pprint import pprint

header = ['Room', '8:00 AM', '8:30 AM', '9:00 AM', '9:30 AM', '10:00 AM', '10:30 AM',
          '11:00 AM', '11:30 AM', '12:00 PM', '12:30 PM', '1:00 PM', '1:30 PM', '2:00 PM',
          '2:30 PM', '3:00 PM', '3:30 PM', '4:00 PM', '4:30 PM', '5:00 PM', '5:30 PM',
          '6:00 PM', '6:30 PM', '7:00 PM', '7:30 PM', '8:00 PM', '8:30 PM', '9:00 PM',
          '9:30 PM', '10:00 PM', '10:30 PM', '11:00 PM', '11:30 PM', '12:00 AM',
          '12:30 AM', '1:00 AM', '1:30 AM']

rooms = ['Crystal', 'S201', 'MacArthur', 'Mitchell', 'Walker', 'Pabst', 'Schlitz',
         'Wright B', 'Wright C', 'Kilbourn', 'Empire']

def plot_from_reader(reader, worksheet, time_lookup, room_lookup, vert_offset, panel_format):
        for row in reader:
            title = row["title"]
            room = row["room"]

            if room == "Sponsor's Lounge" or room == "Hotel Lower Lobby":
                title = f"{title} ({room})"
                desc = f"Location: {room}\n"

            length = row["length"]
            if length and length.isnumeric() is False:
                continue

            day = row["day"]
            time = row["time"]

            print(f"{day} : {room} : {title} : {time} {length}")

            if room in room_lookup:
                v_off = vert_offset[day]
                if length == 30:
                    worksheet.write(v_off + room_lookup[room], time_lookup[time], title, panel_format)
                else:
                    add_cols = int(int(length)/30) - 1
                    worksheet.merge_range(v_off + room_lookup[room], time_lookup[time], 
                                          v_off + room_lookup[room], time_lookup[time] + add_cols,
                                          title, panel_format)


def main():
    """The main program -- do I really need to docstring this?"""
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input", help="Input tabfile", required=True)
    parser.add_argument("-a", "--add", help="Additional tabfile", required=True)
    args = parser.parse_args()

    workbook = xlsxwriter.Workbook("transposed.xlsx")
    worksheet = workbook.add_worksheet()

    header_format = workbook.add_format({"bold": True, "align": "center"})

    panel_format = workbook.add_format(
        {
            "bold": 0,
            "border": 1,
            "align": "center",
            "valign": "vcenter",
            "fg_color": "green",
        }
    )

    time_lookup = {}
    room_lookup = {}

    vert_leap_per_day = len(rooms) + 3

    worksheet.write(0, 0, "Thursday", header_format)    
    worksheet.write(vert_leap_per_day, 0, "Friday", header_format)    
    worksheet.write(vert_leap_per_day * 2, 0, "Saturday", header_format)    
    worksheet.write(vert_leap_per_day * 3, 0, "Sunday", header_format)    

    vert_offset = {
        "thursday": 1,
        "friday": (1 + vert_leap_per_day),
        "saturday": (1 + (vert_leap_per_day * 2)),
        "sunday": (1 + (vert_leap_per_day * 3))        
    }

    for i in range(len(header)):
        worksheet.write(vert_offset["thursday"], i, header[i], header_format)
        worksheet.write(vert_offset["friday"], i, header[i], header_format)
        worksheet.write(vert_offset["saturday"], i, header[i], header_format)
        worksheet.write(vert_offset["sunday"], i, header[i], header_format)
        time_lookup[header[i]]=i

    for i in range(len(rooms)):
        worksheet.write(vert_offset["thursday"] + i + 1, 0, rooms[i], header_format)
        worksheet.write(vert_offset["friday"] + i + 1, 0, rooms[i], header_format)
        worksheet.write(vert_offset["saturday"] + i + 1, 0, rooms[i], header_format)
        worksheet.write(vert_offset["sunday"] + i + 1, 0, rooms[i], header_format)
        room_lookup[rooms[i]]=i+1

    for filename in [args.input, args.add]:
        with open(filename, "r", encoding="utf-8") as file:
            reader = csv.DictReader(file, delimiter="\t")
            plot_from_reader(reader, worksheet, time_lookup, room_lookup, vert_offset, panel_format)

    workbook.close()


if __name__ == "__main__":
    main()