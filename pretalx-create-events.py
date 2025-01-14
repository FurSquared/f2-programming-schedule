#!/usr/bin/env python3
""" Add new events to pretalx from the panel list
"""

import time
import sys

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


def add_session(brows, title, desc, length, category):
    brows.get("https://schedule.fursquared.com/orga/event/f2-2025/submissions/new")

    p_title = WebDriverWait(brows, 20).until(
        EC.visibility_of_element_located((By.ID, "id_title"))
    )
    p_title.send_keys(title)

    brows.find_element_by_id("id_abstract").send_keys(desc)

    # Select "submitted"
    brows.find_element(
        "xpath", "/html/body/div/div/main/form/fieldset/div[4]/div/div/div[1]"
    ).click()
    brows.find_element("xpath", '//*[@id="choices--id_state-item-choice-1"]').click()

    # Type of talk?
    brows.find_element(
        "xpath", "/html/body/div/div/main/form/fieldset/div[6]/div/div/div[1]/div/div"
    ).click()
    brows.find_element(
        "xpath", '//*[@id="choices--id_submission_type-item-choice-2"]'
    ).click()

    brows.find_element_by_id("id_duration").send_keys(length)

    # Category as pretalx track
    # brows.find_element("xpath", "/html/body/div/div/main/form/fieldset/div[7]/div/div/div[1]/div/div").click()
    # brows.find_element("xpath", "/html/body/div/div/main/form/fieldset/div[7]/div/div/div[2]/input").send_keys(category)

    # Save
    brows.find_element(
        "xpath", "/html/body/div/div/main/form/fieldset/div[16]/span[2]/button"
    ).click()
    time.sleep(5)

    # id_internal_notes
    # room
    # id_track
    # id_email (opt)
    # id_speaker_name (opt)


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

    time.sleep(2)
    return brows


def main():
    """The main program -- do I really need to docstring this?"""

    print("Logging in.")
    creds = get_credentials()
    brows = login(creds)
    _ = ActionChains(brows)

    with open(
        "Master Schedule Document- F2 2025 - Panels To Schedule.tsv",
        "r",
        encoding="utf-8",
    ) as file:
        reader = csv.DictReader(file, delimiter="\t")
        for row in reader:
            title = row["Panel / Event Title:"]
            desc = row["Event / Panel Description:"]
            category = row["Category:"]

            length = row["Event Length"].split(" ")[0]
            if length and length.isnumeric() is False:
                length = ""

            pt_id = row["Pretalx ID"]
            if len(pt_id) > 2:
                print(f"SKIPPING: (already has ID: {pt_id}) {title}")
                continue
            if category.startswith("Board"):
                print(f"SKIPPING: (game) {title}")
                continue
            if len(desc) < 3:
                print(f"WARNING: (nodesc) {title}")
                desc = "Needs a description."

            print(f"CREATING: {title}")
            add_session(brows, title, desc, length, category)


if __name__ == "__main__":
    main()
