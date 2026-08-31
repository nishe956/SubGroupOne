"""Pagination appliquée par défaut à toutes les vues liste.

Sans pagination, chaque `ListAPIView` renvoyait l'intégralité de sa table :
extraction de masse triviale une fois authentifié, et consommation mémoire
proportionnelle à la base sur un simple GET du catalogue public.
"""
from rest_framework.pagination import PageNumberPagination


class PaginationStandard(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    # Borne haute : sans elle, ?page_size=1000000 annulerait la protection.
    max_page_size = 100
