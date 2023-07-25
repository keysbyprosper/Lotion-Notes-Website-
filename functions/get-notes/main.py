# add your get-notes function here
import boto3
from boto3.dynamodb.conditions import Key
import json

dynamodb_resource = boto3.resource("dynamodb")
table = dynamodb_resource.Table("lotion-30145690")

def handler(event, context):
    email = event["queryStringParameters"]["email"]

    try: 
        res = table.query(KeyConditionExpression = Key("email").eq(email))
        return{
            "statusCode": 200,
            "body": json.dumps(
                res["Items"]
            )
        }
    except Exception as exp:
        print(f"exception: {exp}")
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": str(exp)
            })
        }

