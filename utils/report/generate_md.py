"""generate_md.py

This file is simple, it forms a very rigid (fragile) script that will turn a JUnit XML and some metadata
into a nicely formatted markdown table and write it to a file!

python3 generate_slack_message.py <path to folder with xml results> <destination filepath> <snapshot> <stage> <platform> 

"""

import os, sys, untangle, json
from helpers import *


if __name__ == "__main__":

    #-----Check and process arguments-----#
    if len(sys.argv) < 10:
        print("""
Missing arguments!  
Usage: python3 generate_md.py <path to folder with xml results> <destination filepath> <snapshot> <stage> <platform> <hub-cluster-version> <hub-cluster-console> <import-cluster-version> <import-cluster-console>
""")
        exit(1)

    test_results = None
    _test_foldername = sys.argv[1]
    _dest_filename = sys.argv[2]
    _snapshot = sys.argv[3]
    _stage = sys.argv[4]
    _platform = sys.argv[5]
    _hub_cluster_version = sys.argv[6]
    _hub_cluster_console = sys.argv[7]
    _import_cluster_version = sys.argv[8]
    _import_cluster_console = sys.argv[9]
    _job_url = ""
    _ignorelist_filepath = None

    #-----Load our build URL, or a dummy value (and print out a warning if not set)----#
    try:
        _url = os.getenv("BUILD_URL") if os.getenv("BUILD_URL") is not None else "No Job URL"
        _job_url = "Job URL: " + _url + "\n"
    except AttributeError as ex:
        print("No env var for BUILD_URL, skipping printing the URL.", file=sys.stderr)

    _ignorelist_filepath = os.getenv("IGNORELIST_FILEPATH")
    _ignorelist = []
    if _ignorelist_filepath is not None:
        with open(_ignorelist_filepath, "r") as file:
            _ignorelist=json.load(file)["ignored_tests"]

    _total, _failed, _skipped, _passed, _ignored = get_folder_counts(_test_foldername)
    _details = get_folder_details(_test_foldername, _ignorelist)
    _status = get_status(_test_foldername, _ignorelist)

    _message = ""
    # Choose our heading (full failure, partial failure, full success)
    if _failed == _total and _status != 0:
        _message = _message + f"# :red_circle: {_snapshot} Failed when running {_stage} on {_platform} environment\n\n## {_job_url}\n\n"
    elif _status != 0:
        _message = _message + f"# :warning: {_snapshot} had some failures when running {_stage} on {_platform} environment\n\n## {_job_url}\n\n"
    else:
        _message = _message + f"# :white_check_mark: {_snapshot} Passed when running {_stage} on {_platform} environment\n\n## {_job_url}\n\n"

    _message = _message + f"Hub Cluster Version: {_hub_cluster_version}\n\n"
    _message = _message + f"Hub Cluster: https://{_hub_cluster_console}\n\n"
    _message = _message + f"Managed Cluster Version: {_import_cluster_version}\n\n"
    _message = _message + f"Managed Cluster: {_import_cluster_console}\n\n"
    _message = _message + f"## Tests:\n\n|Results|Test|\n|---|---|\n"

    # Handle each cases' entry in the table
    for test in _details:
        if test['failed']:
            if test['ignored']:
                _message = _message + f"| :large_orange_diamond: | {test['name']} |\n"
            else:
                _message = _message + f"| :x: | {test['name']} |\n"
        elif test['skipped']:
            _message = _message + f"| :large_blue_circle: | {test['name']} |\n"
        else:
            _message = _message + f"| :white_check_mark: | {test['name']} |\n"
    # and close the table once we're done.
    _message = _message + "\n\n---\n\n"

    # Print the full message for each failure after the table
    if _failed > 0:
        _message = _message + "### Failed Test Details\n\n"
    for test in _details:
        if test["failed"]:
            if test["ignored"]:
                _message = _message + f"#### :large_orange_diamond: {test['name']}"
            else:
                _message = _message + f"#### :x: {test['name']}"
            _message = _message + f"""


```
{test['message']}
```
                        
"""
    with open(_dest_filename, "w+") as dest_file:
        dest_file.write(_message)