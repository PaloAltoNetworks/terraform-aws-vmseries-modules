import boto3
import botocore
from datetime import datetime

ec2_client = boto3.client('ec2')
asg_client = boto3.client('autoscaling')


def lambda_handler(event, context):
    if event["detail-type"] == "EC2 Instance-launch Lifecycle Action":
        instance_id = event["detail"]["EC2InstanceId"]

        instance = ec2_client.describe_instances(InstanceIds=[instance_id])
        vpc_id = instance['Reservations'][0]['Instances'][0]['VpcId']
        az = instance['Reservations'][0]['Instances'][0]['Placement']['AvailabilityZone']
        possible_subnets = get_subnets(vpc_id, az)

        if "nic1" in possible_subnets:

            nic1_subnet_id = possible_subnets['nic1']
            log("debug: nic1_subnet_id: {}".format(nic1_subnet_id))
    
            interface_id = create_interface(nic1_subnet_id, event, instance_id)
            log("debug: interface_id: {}".format(interface_id))
    
            attachment = attach_interface(interface_id, instance_id)
            log("debug: attachment: {}".format(attachment))
    
            delete = ec2_client.modify_network_interface_attribute(
                Attachment={
                    'AttachmentId': attachment,
                    'DeleteOnTermination': True,
                },
                NetworkInterfaceId = interface_id,
            )
            log("debug: delete: {}".format(delete))
    
            if interface_id and not attachment:
                log("Removing network interface {} after attachment failed.".format(interface_id))
                delete_interface(interface_id)

        try:
            asg_client.complete_lifecycle_action(
                LifecycleHookName=event['detail']['LifecycleHookName'],
                AutoScalingGroupName=event['detail']['AutoScalingGroupName'],
                LifecycleActionToken=event['detail']['LifecycleActionToken'],
                LifecycleActionResult='CONTINUE'
            )

        except botocore.exceptions.ClientError as e:
            log("Error completing life cycle hook for instance {}: {}".format(instance_id, e.response['Error']['Code']))
            log('{"Error": "1"}')


def get_subnets(vpc_id, az):
    res = {}
    ec2 = boto3.resource('ec2')
    vpc = ec2.Vpc(vpc_id)
    for subnet in vpc.subnets.all():
        if subnet.availability_zone == az:
            for tag in subnet.tags:
                if tag['Key'] == 'vmseries':
                  res[tag['Value']] = subnet.subnet_id
    return res


def create_interface(subnet_id, event,instance_id):
    network_interface_id = None

    try:
        network_interface = ec2_client.create_network_interface(SubnetId=subnet_id)
        network_interface_id = network_interface['NetworkInterface']['NetworkInterfaceId']
        log("Created network interface: {}".format(network_interface_id))
    except botocore.exceptions.ClientError as e:
        log("Error creating network interface: {}".format(e.response['Error']['Code']))

    return network_interface_id


def attach_interface(network_interface_id, instance_id):
    attachment = None

    if network_interface_id and instance_id:
        try:
            attach_interface = ec2_client.attach_network_interface(
                NetworkInterfaceId=network_interface_id,
                InstanceId=instance_id,
                DeviceIndex=1
            )
            attachment = attach_interface['AttachmentId']
            log("Created network attachment: {}".format(attachment))
        except botocore.exceptions.ClientError as e:
            log("Error attaching network interface: {}".format(e.response['Error']['Code']))

    return attachment


def delete_interface(network_interface_id):
    try:
        ec2_client.delete_network_interface(
            NetworkInterfaceId=network_interface_id
        )
        return True

    except botocore.exceptions.ClientError as e:
        log("Error deleting interface {}: {}".format(network_interface_id, e.response['Error']['Code']))


def log(message):
    print('{}Z {}'.format(datetime.utcnow().isoformat(), message))
