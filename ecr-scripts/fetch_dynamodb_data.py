import sys
import boto3
import json
from decimal import Decimal

def default(obj):
    if isinstance(obj, Decimal):
        # Convert decimal instances to floats or ints
        if obj % 1 == 0:
            return int(obj)
        else:
            return float(obj)
    raise TypeError("Object of type '%s' is not JSON serializable" % type(obj).__name__)
# Read input from stdin
input_json = sys.stdin.read()
input_data = json.loads(input_json)
# Initialize a DynamoDB client
aws_region = input_data.get('aws_region', 'us-east-1')

dynamodb = boto3.resource("dynamodb", region_name=aws_region)
table_name = "http_crud_backend"
table = dynamodb.Table(table_name)

response = table.scan()

# Convert items to a map with string keys and string values
items_map = {item["id"]: json.dumps(item, default=default) for item in response['Items']}

# Output the JSON encoded map
print(json.dumps(items_map))
