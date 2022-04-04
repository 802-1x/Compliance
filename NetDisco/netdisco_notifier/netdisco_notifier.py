import csv
import requests
import smtplib
import argparse
import json
import pprint
import copy
from datetime import datetime
from lxml import html
from email.message import EmailMessage

pp = pprint.PrettyPrinter(indent=4)

class netdisco_notifier():
    def __init__(self):
        self.config = {}

        parser = argparse.ArgumentParser(description='NetDisco Notifier Script')
        parser.add_argument("--config_file", type=str, default="notifier_config.json", help="filename of json config file")
        parser.add_argument("--notify", type=str, default="all", help="switch to determine which reports to email. choose from all, immediate or historic")
        args = parser.parse_args()

        # load config file
        try:
            with open(args.config_file) as config_file:
                self.config = json.load(config_file)
        except:
            print("WARNING: Could not open config file!! Loading the default config file and setting DEBUG to True")
            with open("notifier_config.json") as config_file:
                self.config = json.load(config_file)
            self.config['DEBUG'] = True

        print("DEBUG = ", self.config['DEBUG'])
        if self.config['DEBUG']:
            pp.pprint(self.config)

        self.notify = args.notify
        print("running netdisco_notifier.py at ", datetime.now(), "with notification level =", self.notify)

        self.reports = copy.deepcopy(self.config['reports_of_interest'])

        for report_key in self.reports:
            self.reports[report_key]["message_contents_string"] = ""

    def download_csv_files(self):
        with requests.Session() as s:
            # Log into netdisco
            result = s.get(self.config['login_url'])
            tree = html.fromstring(result.text)
            result = s.post(
                     self.config["login_url"],
                     data = self.config['login_payload'],
                     headers = dict(referer=self.config['login_url'])
                     )

            for report_key in self.reports:

                # Download CSV files
                try:
                    download = s.get(self.reports[report_key]["url"])
                    decoded_content = download.content.decode('utf-8')
                    cr = csv.reader(decoded_content.splitlines(), delimiter=',')
                except:
                    error_message = "Error downloading the CSV file for {0}\n"
                    print(error_message.format(self.reports[report_key]['name']))
                    # set the email body to be the error message
                    self.reports[report_key]["message_contents_string"] = str(error_message.format(self.reports[report_key]['name']))

                # Format CSV file
                my_list = list(cr)
                try:
                    self.reports[report_key]["headings"] = my_list[0]
                    self.reports[report_key]["data"] = my_list[1:]
                except (IndexError, KeyError):
                    error_message = "Nothing in the CSV file for {0}, changing notify status to none"
                    print(error_message.format(self.reports[report_key]['name']))
                    self.reports[report_key]["notify"] = "none" # don't send email if nothing in the CSV

                # Print details straight from dictionary
                if self.config['DEBUG']:
                    print(self.reports[report_key]["headings"])
                    for row in self.reports[report_key]["data"]:
                        print(row)

    def create_messages(self, report_key):
        message_contents = []

        message_heading = "The following {0} report items were detected:\n"
        message_contents.append(message_heading.format(self.reports[report_key]['name']))

        human = "\t" + self.reports[report_key]["human_readable"] + "\n"
        rows = self.reports[report_key]["csv_column_order"]

        rows_string = ''
        for entry in rows:
            rows_string = rows_string + "row[" + str(entry) + "],"
        rows_string = rows_string[:-1] #dodgy fix to remove last comma

        try:
            for row in self.reports[report_key]["data"]:
                human_string = "human.format(" + rows_string + ")"
                human_string_eval = str(eval(human_string))

                message_contents.append(human_string_eval)
        except (IndexError, KeyError):
            error_message = "Error detecting {0} problems: you should check netdisco manually"
            message_contents.append(error_message.format(self.reports[report_key]['name']))
            message_contents.append("\n") # prints new line

        # convert list into big string
        separator = ''
        self.reports[report_key]["message_contents_string"] = separator.join(message_contents)

        if self.config['DEBUG']:
            print(self.reports[report_key]["message_contents_string"])

    def send_emails(self):
        actions = []
        messages = []

        # want to send every report (including none)
        if self.notify == "all":
            actions.append("immediate")
            actions.append("historic")
            actions.append("none")

        # want to send only immediate reports when nofigy is set to immediate 
        elif self.notify == "immediate":
            actions.append("immediate")

        # want to send only historic reports when nofigy is set to historic 
        elif self.notify == "historic":
            actions.append("historic")
        else:
            pass
        print("Doing actions: ", actions)

        for report_key in self.reports:
            if self.reports[report_key]["notify"] in actions:
                print("Creating message for report:", self.reports[report_key]["name"])

                new_message = EmailMessage()
                new_message.set_content(self.reports[report_key]["message_contents_string"])

                new_message['Subject'] = str("NetDisco Netowork Notification: "
                                             + self.reports[report_key]["name"]
                                             + " (notification level = "
                                             + self.reports[report_key]["notify"]
                                             + ")")

                new_message['From'] = self.config['email']['from_address']
                new_message['To'] = self.config['email']['to_address']
                messages.append(new_message)

        s = smtplib.SMTP(self.config['email']['smtp_server'])

        for message in messages:
            s.send_message(message)

        s.quit()

    def _save_current_config_as_json_file(self):
        with open('output.json', 'w') as outfile:
            json.dump(self.config, outfile, indent=2, sort_keys=True)

if __name__ == "__main__":
    script = netdisco_notifier()

    script.download_csv_files()

    #script.get_data_from_postgres()
    #script.process_data()

    for report_key in script.reports:
        script.create_messages(report_key)

    script.send_emails()
