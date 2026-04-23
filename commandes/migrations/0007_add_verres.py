from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('commandes', '0006_add_gps_coords'),
    ]

    operations = [
        migrations.AddField(
            model_name='commande',
            name='type_verre',
            field=models.CharField(blank=True, max_length=50),
        ),
        migrations.AddField(
            model_name='commande',
            name='options_verres',
            field=models.JSONField(blank=True, default=list),
        ),
        migrations.AddField(
            model_name='commande',
            name='prix_verres',
            field=models.DecimalField(blank=True, decimal_places=2, max_digits=10, null=True),
        ),
    ]
