import csv
import requests
import smtplib
from lxml import html
from email.message import EmailMessage

DEBUG=False

payload = {
          "username": "user",
          "password": "pass"
          }

LOGIN_URL = "http://netdisco:5000/login"
DUPLEX_MISMATCH_URL = 'http://netdisco:5000/ajax/content/report/duplexmismatch?'

problem_items = {
                "duplex_mismatch":{"url":"http://netdisco:5000/ajax/content/report/duplexmismatch?"},
                "port_utilisation":{"url":"http://netdisco:5000/ajax/content/report/portutilization?age_num=3&age_unit=months"},
                "port_vlan_mismatch":{"url":"http://netdisco:5000/ajax/content/report/portvlanmismatch?"},
                "ports_that_are_blocking":{"url":"http://netdisco:5000/ajax/content/report/portblocking?"}
                } 

#Port
#    Error Disabled Ports? # need to actually disable a port to test this one
#    Ports that are blocking

with requests.Session() as s:
    # Log into netdisco
    result = s.get(LOGIN_URL)
    tree = html.fromstring(result.text)
    result = s.post(
             LOGIN_URL,
             data = payload,
             headers = dict(referer=LOGIN_URL)
             )

    for key in problem_items:
        # Download CSV files
        download = s.get(problem_items[key]["url"])
        decoded_content = download.content.decode('utf-8')
        cr = csv.reader(decoded_content.splitlines(), delimiter=',')

        # Format CSV file
        my_list = list(cr)
        problem_items[key]["headings"] = my_list[0]
        problem_items[key]["data"] = my_list[1:]

        # Print details straight from dictionary
        if DEBUG:
            print(problem_items[key]["headings"])
            for row in problem_items[key]["data"]:
                pass
                print(row)

    message_contents = []
    # Human Friendly Presentation

    # Duples Mismatch
    message_contents.append("The following Duplex Mismatch problem items were detected:\n")
    duplex_mismatch_human = "\tPort {0} in switch {1} is running at {2}, but port {3} in switch {4} is running at {5}\n"
    try:
        for row in problem_items["duplex_mismatch"]["data"]:
            message_contents.append(duplex_mismatch_human.format(row[1],row[0],row[2],row[4],row[3],row[5]))
    except IndexError:
        message_contents.append("Error detecting Duplex Mismatch problems: you should check netdisco manually")
    message_contents.append("\n") # prints new line

    # Port Utilisation
    message_contents.append("The following Port Utilisation problem items were detected:\n")
    port_utilisation_human = "\tDevice {0} only has {1} free ports\n"
    port_utilisation_warning_threshold = 3
    try:
        for row in problem_items["port_utilisation"]["data"]:
            # Check if there are less than the threshold number of ports free
            if int(row[4]) < port_utilisation_warning_threshold:
                message_contents.append(port_utilisation_human.format(row[0],row[4]))
    except IndexError:
        message_contents.append("Error detecting Port Utilisation problems: you should check netdisco manually\n")
    message_contents.append("\n") # prints new line

    # Port VLAN Mismatch
    message_contents.append("The following Port VLAN Mismatch problem items were detected (see netdisco for more details):\n")
    port_vlan_mismatch_human = "\tPort {0} in switch {1} has mismatch VLANs with port {2} in switch {3}\n"
    try:
        for row in problem_items["port_vlan_mismatch"]["data"]:
            message_contents.append(port_vlan_mismatch_human.format(row[1],row[0],row[4],row[3]))
    except IndexError:
        message_contents.append("Error detecting Port Utilisation problems: you should check netdisco manually\n")
    message_contents.append("\n") # prints new line

    # Ports that are Blocking
    message_contents.append("The following Port Blocking problem items were detected:\n")
    ports_that_are_blocking_human = "\tDevice {0} is {1} on port {2} ({3})\n"
    try:
        for row in problem_items["ports_that_are_blocking"]["data"]:
            message_contents.append(ports_that_are_blocking_human.format(row[0],row[3],row[1],row[2]))
    except IndexError:
        message_contents.append("Error detecting Port Blocking problems: you should check netdisco manually\n")
    message_contents.append("\n") # prints new line

    # convert list into big string
    separator = ''
    message_contents_joined = separator.join(message_contents)
    print(message_contents_joined)

    # Send email
    msg = EmailMessage()
    msg.set_content(message_contents_joined)

    msg['Subject'] = f'email from python'
    msg['From'] = "netdisco@test"
    msg['To'] = "test@test"

    s = smtplib.SMTP('SMTPSERVER')
    s.send_message(msg)
    s.quit()
