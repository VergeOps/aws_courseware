# Backup all in-use volumes in all regions

import boto3
import datetime

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')

    # Get list of regions
    regions = ec2.describe_regions().get('Regions',[] )

    # Connect to region
    ec2 = boto3.client('ec2', region_name='us-west-2')

    # Get all in-use volumes in all regions
    result = ec2.describe_volumes( Filters=[{'Name': 'tag-key', 'Values': ['Backup']}])

    for volume in result['Volumes']:
        print("Backing up %s in %s" % (volume['VolumeId'], volume['AvailabilityZone']))

        # Create snapshot
        result = ec2.create_snapshot(VolumeId=volume['VolumeId'],Description='Nightly snapshot')

        # Get snapshot resource
        ec2resource = boto3.resource('ec2', region_name='us-west-2')
        snapshot = ec2resource.Snapshot(result['SnapshotId'])

        volumename = 'N/A'

        # Find name tag for volume if it exists
        if 'Tags' in volume:
            for tags in volume['Tags']:
                if tags["Key"] == 'Name':
                    volumename = tags["Value"]

        # Add volume name to snapshot for easier identification
        delete_date = datetime.date.today() + datetime.timedelta(days=10)
        delete_fmt = delete_date.strftime('%Y-%m-%d')
        print("Will delete snapshots on %s" % (delete_fmt))

        snapshot.create_tags(Tags=[{'Key': 'Name','Value': volumename}, {'Key': 'Retention','Value': '10'}, {'Key': 'DeleteOn', 'Value': delete_fmt}])

    
