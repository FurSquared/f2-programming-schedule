#!/usr/bin/env python3
""" Add new events to pretalx from the panel list
"""

import argparse
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


def add_session(brows, title, desc):
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

    # Save
    brows.find_element(
        "xpath", "/html/body/div/div/main/form/fieldset/div[16]/span[2]/button"
    ).click()

    time.sleep(5)

    raw_url = brows.current_url
    return raw_url.split("/")[-2]


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
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input", help="Input tabfile", required=True)
    parser.add_argument(
        "--id", help="Column name for Pretalx ID in input tabfile", default="id"
    )
    parser.add_argument(
        "--title", help="Column name for panel title in input tabfile", default="title"
    )
    parser.add_argument(
        "--desc",
        help="Column name for panel description in input tabfile",
        default="desc",
    )
    args = parser.parse_args()

    creds = get_credentials()
    brows = login(creds)
    _ = ActionChains(brows)

    with open(args.input, "r", encoding="utf-8") as file:
        reader = csv.DictReader(file, delimiter="\t")

        for row in reader:
            pt_id = row[args.id]
            title = row[args.title]
            desc = row[args.desc]

            if len(pt_id) > 2:
                print(f"SKIP\t{pt_id}\t{title}")
                continue

            new_id = add_session(brows, title, desc)
            print(f"CREATE\t{new_id}\t{title}")


if __name__ == "__main__":
    main()
