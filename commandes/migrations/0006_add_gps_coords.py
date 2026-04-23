from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('commandes', '0005_add_adresse_livraison'),
    ]

    operations = [
        migrations.AddField(
            model_name='commande',
            name='latitude',
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='commande',
            name='longitude',
            field=models.FloatField(blank=True, null=True),
        ),
    ]
