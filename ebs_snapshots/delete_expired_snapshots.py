import boto3
import re
import datetime
import base64
import os
import json


def lambda_handler(event, context):
    ec = boto3.client('ec2', region_name='us-west-2')

    delete_on = datetime.date.today().strftime('%Y-%m-%d')
    filters = [
        {'Name': 'tag-key', 'Values': ['DeleteOn']},
        {'Name': 'tag-value', 'Values': [delete_on]},
    ]
    snapshot_response = ec.describe_snapshots(Filters=filters)

    print("Found %d snapshots that need deleting in region %s on %s" % (
        len(snapshot_response['Snapshots']),
        'us-west-2',
        delete_on))

    for snap in snapshot_response['Snapshots']:
        print("Deleting snapshot %s" % snap['SnapshotId'])
        ec.delete_snapshot(SnapshotId=snap['SnapshotId'])
