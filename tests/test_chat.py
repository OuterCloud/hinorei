import requests

url = "http://localhost:8000/api/v1/chat"
payload = {"message": "你好，介绍一下你自己"}

response = requests.post(url, json=payload)
print(response.json())
