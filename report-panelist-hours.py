#!/usr/bin/env python3
""" Room Reports - Schedule for each room
"""

import sys

from datetime import datetime, timedelta
from pprint import pprint
from time import sleep

import argparse
import csv
import re

def main():
    """The main program -- do I really need to docstring this?"""
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input", action='append', help="Input tabfile", required=True)
    args = parser.parse_args()

    info = {}

    for input_file in args.input:
        with open(input_file, "r", encoding="utf-8") as file:
            reader = csv.DictReader(file, delimiter="\t")
            for row in reader:
                title = row["title"]
                length = row["length"]

                # No credit for closed rehearsals
                if 'Rehearsal' in title and 'Choir' not in title:
                    continue
 
                # Open room times don't count
                if title == 'Video Gaming':
                    continue

                panelists = []
                for field in ['hosts', 'guests']:
                    if field in row:
                        more = re.split('[,;] ?', row[field])
                        panelists = panelists + more

                for panelist in panelists:

                    # Skip non-names
                    if panelist in ['', 'TBA', 'N/A', 'n/a', 'and more', 'the ghosts', 'Twisted Tails', 'Video Game Staff', 'FurSquared'] or 'guests' in panelist:
                        continue

                    # Correcting some names
                    if panelist == 'a fox named coyote':
                        panelist = 'A Fox Named Coyote'
                    if panelist == 'Boozy':
                        panelist = 'Boozy Badger'
                    if panelist == 'Citrine':
                        panelist = 'Citrine Husky'
                    if panelist == 'Iggy & so many more!':
                        panelist = 'Iggy'
                    if panelist == 'Kashi':
                        panelist = 'Kashiru'
                    if panelist == 'Keyotter' or panelist  == 'keyotter':
                        panelist = 'Key Otter'
                    if panelist == 'Purple Dragonmage':
                        panelist = 'Purple DragonMage'
                    if panelist == 'wolfletech':
                        panelist = 'Wolfletech'

                    if panelist not in info:
                        info[panelist] = {'panels': [], 'total': 0}
                    info[panelist]['total'] += int(length)
                    info[panelist]['panels'].append(title)


    for panelist, detail in sorted(info.items()):
        hours = int((detail['total'] * 2) / 60)
        print(f"\n\n{panelist} : {hours} hours\n")
        print("\t", ', '.join(sorted(info[panelist]['panels'])))

if __name__ == "__main__":
    main()
