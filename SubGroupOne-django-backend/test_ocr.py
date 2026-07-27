import requests
import os 

url = 'http://127.0.0.1:8000/api/ordonnances/scanner/'
token = os.getenv('JWT_TOKEN_TEST', '')

headers = {'Authorization': f'Bearer {token}'}

with open('ordonnance_test3.png', 'rb') as f:
    files = {'image': ('ordonnance_test3.png', f, 'image/png')}
    response = requests.post(url, headers=headers, files=files)
    print(response.json())