from json import loads
from logging import getLogger, basicConfig, INFO, DEBUG
from os import getenv

from boto3 import client
from botocore.exceptions import ClientError


class ConfigureLogger:
    def __init__(self, *args, **kwargs):
        self.logger = getLogger(self.__class__.__name__)
        basicConfig(format='%(asctime)s %(message)s')
        self.logger.setLevel(DEBUG if getenv("logger_level") else INFO)


class VMSeriesInterfaceScaling(ConfigureLogger):
    def __init__(self, asg_event: dict):
        super().__init__()
        self.ec2_client = client('ec2')
        self.asg_client = client('autoscaling')
        self.main(asg_event)

    def main(self, asg_event: dict):
        """
        Main function, used for setting parameters and glue other functions logic.

        :param asg_event: dict data from Lambda handler
        :return: none
        """
        # Check if we were called by a lifecycle action
        if not asg_event["detail-type"] == "EC2 Instance-launch Lifecycle Action":
            raise Exception("Non valid event type!")

        instance_id = asg_event["detail"]["EC2InstanceId"]
        instance_zone, subnet_id = self.inspect_ec2_instance(instance_id)

        self.logger.info(f"Instance ID: {instance_id}, Instance zone: {instance_zone}")
        self.logger.debug(f"Subnet ID of the first interface: {subnet_id}")

        # Build interface settings
        interfaces = self.create_interface_settings(instance_zone)
        for interface in interfaces:
            self.logger.info(
                f"Found new interface to create: id={interface['index'] + 1}, subnet={interface['subnet']}, "
                f"security_group={interface['sg']}")
            self.logger.info(f"Interface structure: {interface}")
            self.create_and_configure_new_network_interface(instance_id, interface)

        # Complete lifecycle action
        self.complete_lifecycle(asg_event['detail'])

    @staticmethod
    def create_interface_settings(instance_zone: str) -> list:
        """
        This function normalize data with settings of each ENI.

        :param instance_zone: EC2 Instance availability zone
        :return: list of dict with interface settings
        """
        settings = loads(getenv('lambda_config'))
        interface = {}
        for eni, sett in settings.items():
            for k, v in sett.items():
                interface[eni] = {} if eni not in interface.keys() else interface[eni]
                interface[eni]["index"] = int(v) if 'device_index' in k else interface.get(eni).get('index')
                interface[eni]["sg"] = v[0] if 'security_group_ids' in k else interface.get(eni).get('sg')
                interface[eni]["c_pub_ip"] = v if 'create_public_ip' in k else interface.get(eni).get('c_pub_ip')
                interface[eni]["s_dest_ch"] = v if 'source_dest_check' in k else interface.get(eni).get('s_dest_ch')
                if 'subnet_id' in k:
                    for az, subnet in v.items():
                        if az == instance_zone:
                            interface[eni]["subnet"] = subnet
        interfaces = sorted((interface for interface in interface.values()), key=lambda x: x["index"])
        return interfaces

    def inspect_ec2_instance(self, instance_id: str) -> tuple:
        """
        Helper class used for return EC2 Instance data.

        :param instance_id: EC2 Instance id.
        :return: availability zone and subnet id of EC2 instance
        """

        instance_info = self.ec2_client.describe_instances(InstanceIds=[instance_id])['Reservations'][0]['Instances'][0]
        return instance_info['Placement']['AvailabilityZone'], instance_info['SubnetId']

    def create_network_interface(self, instance_id: str, subnet_id: str, sg_id: int) -> str:
        """
        As function name, it creates new ENI, if something wrong it catch error.

        :param instance_id: EC2 Instance id
        :param subnet_id: Subnet id
        :param sg_id: Security group id
        :return: Network Interface id
        """

        self.logger.debug(f"DEBUG: create_interface: instance_id={instance_id}, subnet_id={subnet_id}, sg_id={sg_id}")
        try:
            network_interface = self.ec2_client.create_network_interface(SubnetId=subnet_id, Groups=[sg_id])
            network_interface_id = network_interface['NetworkInterface']['NetworkInterfaceId']
            self.logger.info(f"Created network interface: {network_interface_id}")
            return network_interface_id
        except ClientError as e:
            self.logger.error(f"Error creating network interface: {e.response['Error']['Code']}")

    def create_and_configure_new_network_interface(self, instance_id: str, interface: dict):
        """
        This function call create_network_interface for create new ENI and after that through att_network_interface
        attach ENI to proper EC2 and fix ENI configuration.

        :param instance_id: EC2 Instance id
        :param interface: Interface dict data
        :return: none
        """
        self.logger.info(f"Mock creation interface with options: {instance_id}, {interface}")
        interface_id = self.create_network_interface(instance_id, interface['subnet'], interface['sg'])
        if interface_id:
            attachment_id = self.attach_network_interface(instance_id, interface_id, interface['index'] + 1)
            self.modify_network_interface(interface_id, attachment_id, interface['s_dest_ch'])
            if interface['c_pub_ip']:
                self.add_public_ip_to_eni(interface_id)

    def add_public_ip_to_eni(self, interface_id: str):
        """
        This function is used to create public ip and associate it with provided ENI ID.

        :param interface_id: Network Interface id
        :return: none
        """

        public_ip_allocation = self.ec2_client.allocate_address(Domain='vpc')
        self.logger.info(f"Created public ip {public_ip_allocation['PublicIp']} for {interface_id}")

        public_ip_association = self.ec2_client.associate_address(
            AllocationId=public_ip_allocation['AllocationId'],
            NetworkInterfaceId=interface_id
        )
        self.logger.debug(f"Successfully created association: {public_ip_association['AssociationId']}")

    def attach_network_interface(self, instance_id: str, interface_id: str, index) -> str:
        """
        This function attach ENI to EC2 Instance.

        :param instance_id: EC2 Instance id
        :param interface_id: Network Interface id
        :param index: ENI index number in EC2 instance
        :return: none
        """

        self.logger.debug(f"DEBUG: attach_interface: instance_id={instance_id}, interface_id={interface_id}, "
                          f"interface_index={index}")
        if instance_id and interface_id:
            try:
                attach_interface_id = self.ec2_client.attach_network_interface(
                    NetworkInterfaceId=interface_id,
                    InstanceId=instance_id,
                    DeviceIndex=index
                )
                attachment_id = attach_interface_id['AttachmentId']
                self.logger.info(f"Created network attachment: {attachment_id}")
                return attachment_id
            except ClientError as e:
                self.delete_interface(interface_id)
                self.logger.error(f"Error attaching network interface {interface_id}: {e.response['Error']['Code']}"
                                  f"Deleting interface.")

    def modify_network_interface(self, interface_id: str, attachment_id: str, source_dest_check: bool = True):
        """
        This function modify ENI to be able to delete it on EC2 termination.

        :param source_dest_check: Enable or disable source destination check in ENI
        :param interface_id: Network Interface id
        :param attachment_id: ENI attachment id
        :return:
        """

        self.logger.debug(f"DEBUG: tune_interface: interface_id={interface_id}, attachment_id={attachment_id}, "
                          f"source_dest_check: {source_dest_check}")
        self.ec2_client.modify_network_interface_attribute(
            Attachment={'AttachmentId': attachment_id, 'DeleteOnTermination': True},
            NetworkInterfaceId=interface_id,
        )
        if not source_dest_check:
            self.ec2_client.modify_network_interface_attribute(
                NetworkInterfaceId=interface_id,
                SourceDestCheck={
                    'Value': source_dest_check,
                }
            )

    def delete_interface(self, interface_id: str):
        """
        This function is used when there was some problem with ENI attachment to EC2 Instance.
        Purpose of it is not creating unused resources.

        :param interface_id: Network Interface id
        :return: none
        """

        self.logger.info(f"Deleting interface with id={interface_id}")
        try:
            self.ec2_client.delete_network_interface(NetworkInterfaceId=interface_id)
        except ClientError as e:
            self.logger.error(f"Error deleting interface {interface_id}: {e.response['Error']['Code']}")

    def complete_lifecycle(self, asg_event: dict):
        """
        If everything was completed, calling this function continue ASG lifecycle.

        :param asg_event: ASG event, dict
        :return: none
        """

        self.logger.debug("DEBUG: complete")
        try:
            self.asg_client.complete_lifecycle_action(
                LifecycleHookName=asg_event['LifecycleHookName'],
                AutoScalingGroupName=asg_event['AutoScalingGroupName'],
                LifecycleActionToken=asg_event['LifecycleActionToken'],
                LifecycleActionResult='CONTINUE'
            )
        except ClientError as e:
            self.logger.error(f"Error completing life cycle hook for instance: {e.response['Error']['Code']}")


def lambda_handler(asg_event, context):
    VMSeriesInterfaceScaling(asg_event)
