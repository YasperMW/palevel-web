import requests

url = "https://api.paychangu.com/direct-charge/payouts/supported-banks?currency=MWK"

headers = {"accept": "application/json"}

response = requests.get(url, headers=headers)

print(response.text)