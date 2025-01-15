#!/usr/bin/env python3
""" Add new events to pretalx from the panel list
"""

import sys

from datetime import datetime, timedelta
from time import sleep

import csv

from selenium import webdriver
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait


def get_credentials() -> dict:
    """Read user and pass from credentials.txt"""
    credentials = {}
    with open("credentials.txt", encoding="utf-8") as file:
        for line in file.readlines():
            try:
                key, value = line.split(": ")
            except ValueError:
                print("Add your email and password in credentials file")
                sys.exit(0)
            credentials[key] = value.rstrip(" \n")
    return credentials


def update_session(brows, pt_id, title, desc, category, room, start, end):
    brows.get(f'https://schedule.fursquared.com/orga/event/f2-2025/submissions/{pt_id}/')

    p_title = WebDriverWait(brows, 20).until(
        EC.visibility_of_element_located((By.ID, "id_title"))
    )
    p_title.clear()
    p_title.send_keys(title)

    p_desc = brows.find_element_by_id("id_abstract")
    p_desc.clear()
    p_desc.send_keys(desc)

    # Set the status to "accepted" when it's anything else
    status = brows.find_element(
        "xpath", "/html/body/div/div/main/h2/span/details/summary/h4/span"
    )
    if status.text != "accepted":
        status.click()
        brows.find_element(
            "xpath", "/html/body/div/div/main/h2/span/details/div/a[1]/span"
        ).click()
        brows.find_element(
            "xpath", "/html/body/div/div/main/form/div[2]/span[2]/button"
        ).click()

    if start and end:
        brows.find_element(By.ID, "id_start").send_keys(start)
        brows.find_element(By.ID, "id_end").send_keys(end)

    # Track select
    track_element = None
    if category.startswith('Music'):
        track_element = '//*[@id="choices--id_track-item-choice-2"]'
    if category.startswith('Social'):
        track_element = '//*[@id="choices--id_track-item-choice-3"]'
    if category.startswith('Convention'):
        track_element = '//*[@id="choices--id_track-item-choice-4"]'

    if track_element:
        brows.find_element(
            "xpath", "/html/body/div/div/main/form/fieldset/div[4]/div/div/div[1]/div/div"
        ).click()
        brows.find_element("xpath", track_element).click()

    # Room select
    room_element = None
    if room == "Crystal":
        room_element = '//*[@id="choices--id_room-item-choice-2"]'
    if room == "S201":
        room_element = '//*[@id="choices--id_room-item-choice-3"]'
    if room == "MacArthur":
        room_element = '//*[@id="choices--id_room-item-choice-4"]'
    if room == "Mitchell":
        room_element = '//*[@id="choices--id_room-item-choice-5"]'
    if room == "Pabst":
        room_element = '//*[@id="choices--id_room-item-choice-6"]'
    if room == "Miller":
        room_element = '//*[@id="choices--id_room-item-choice-7"]'
    if room == "Schlitz":
        room_element = '//*[@id="choices--id_room-item-choice-8"]'
    if room == "Walker":
        room_element = '//*[@id="choices--id_room-item-choice-9"]'
    # Usinger Wright Kilbourn - not in list yet

    if room_element:
        brows.find_element(
            "xpath", "/html/body/div/div/main/form/fieldset/div[2]/div[1]/div/div/div[1]/div/div"
        ).click()
        brows.find_element("xpath", room_element).click()

    # Save!
    brows.find_element(
        "xpath", "/html/body/div/div/main/form/fieldset/div[14]/span[2]/button"
    ).click()
    

def login(creds):
    """Login to Twitter"""
    firefox_options = Options()
    firefox_options.add_argument("--width=1200")
    firefox_options.add_argument("--height=1600")

    brows = webdriver.Firefox(options=firefox_options)
    brows.implicitly_wait(3)
    brows.set_page_load_timeout(20)

    brows.get("https://schedule.fursquared.com/orga/login/")

    username = WebDriverWait(brows, 20).until(
        EC.visibility_of_element_located((By.ID, "id_login_email"))
    )
    username.send_keys(creds["username"])

    password = WebDriverWait(brows, 20).until(
        EC.visibility_of_element_located((By.ID, "id_login_password"))
    )

    password.send_keys(creds["password"])
    password.send_keys(Keys.RETURN)

    sleep(2)
    return brows


def main():
    """The main program -- do I really need to docstring this?"""

    print("Logging in.")
    creds = get_credentials()
    brows = login(creds)
    _ = ActionChains(brows)

    with open("build.tab", "r", encoding="utf-8") as file:
        reader = csv.DictReader(file, delimiter="\t")
        for row in reader:
            pt_id = row["id"]
            title = row["title"]
            desc = row["desc"]
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
                    start = datetime.strptime(f'2025-02-20 {time}', "%Y-%m-%d %I:%M %p")
                if row["day"] == "friday":
                    start = datetime.strptime(f'2025-02-21 {time}', "%Y-%m-%d %I:%M %p")
                if row["day"] == "saturday":
                    start = datetime.strptime(f'2025-02-22 {time}', "%Y-%m-%d %I:%M %p")
                if row["day"] == "sunday":
                    start = datetime.strptime(f'2025-02-23 {time}', "%Y-%m-%d %I:%M %p")
                end = start + timedelta(minutes=int(length))

                start = start.strftime("%m/%d/%Y, %I:%M %p")
                end = end.strftime("%m/%d/%Y, %I:%M %p")

            if pt_id == "":
                continue
            if start == "":
                continue
            print(f"Updating : {pt_id} : {title}")
            update_session(brows, pt_id, title, desc, category, room, start, end)
            sleep(3)


if __name__ == "__main__":
    main()
