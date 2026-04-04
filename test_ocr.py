import requests

url = 'http://127.0.0.1:8000/api/ordonnances/scanner/'
token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzc1Mjg1OTM4LCJpYXQiOjE3NzUyODIzMzgsImp0aSI6IjVlYjZiNjM0ZWI0ZjRhNWM5OTdkYzYwZGJlZWNkNDlkIiwidXNlcl9pZCI6IjIifQ.EFnoJjBy_UG0CdnwCVrdR3xNWR3Yta5ErD50ColZpro'

headers = {'Authorization': f'Bearer {token}'}

with open('ordonnance_test3.png', 'rb') as f:
    files = {'image': ('ordonnance_test3.png', f, 'image/png')}
    response = requests.post(url, headers=headers, files=files)
    print(response.json())