import requests
import base64

with open('photo.jpg', 'rb') as f:
    image_bytes = f.read()
    image_base64 = 'data:image/jpeg;base64,' + base64.b64encode(image_bytes).decode()

url = 'http://127.0.0.1:8000/api/essai/essayer/'
token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzc1Mjg1OTM4LCJpYXQiOjE3NzUyODIzMzgsImp0aSI6IjVlYjZiNjM0ZWI0ZjRhNWM5OTdkYzYwZGJlZWNkNDlkIiwidXNlcl9pZCI6IjIifQ.EFnoJjBy_UG0CdnwCVrdR3xNWR3Yta5ErD50ColZpro'

headers = {'Authorization': f'Bearer {token}'}
data = {'image': image_base64, 'couleur': 'noir'}

response = requests.post(url, headers=headers, json=data)
result = response.json()

if 'image_avec_monture' in result:
    image_data = result['image_avec_monture'].split(',')[1]
    with open('resultat.jpg', 'wb') as f:
        f.write(base64.b64decode(image_data))
    print('Image sauvegardee dans resultat.jpg !')
    print('Points detectes:', result['points_visage_detectes'])
else:
    print('Erreur:', result)