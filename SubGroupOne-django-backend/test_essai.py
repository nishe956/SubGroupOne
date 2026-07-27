import requests
import base64
import os

with open('photo.jpg', 'rb') as f:
    image_bytes = f.read()
    image_base64 = 'data:image/jpeg;base64,' + base64.b64encode(image_bytes).decode()

url = 'http://127.0.0.1:8000/api/essai/essayer/'
token = os.getenv('JWT_TOKEN_TEST', '')

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