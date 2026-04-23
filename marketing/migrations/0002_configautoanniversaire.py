from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('marketing', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='ConfigAutoAnniversaire',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('actif', models.BooleanField(default=False)),
                ('message_template', models.TextField(default="OptiLunette vous souhaite un Joyeux Anniversaire {prenom} ! 🎂\nProfitez de 10% de réduction aujourd'hui avec le code : ANNIV10")),
                ('heure_envoi', models.TimeField(default='08:00')),
                ('date_modification', models.DateTimeField(auto_now=True)),
                ('opticien', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='config_anniversaire', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Config auto anniversaire',
            },
        ),
    ]
