from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    RegisterView, LoginView, ProfileView, ChangePasswordView, 
    UserManagementViewSet, PartnerAssuranceViewSet, AuditLogViewSet, StatisticsView,
    NotificationViewSet
)

router = DefaultRouter()
router.register('manage', UserManagementViewSet, basename='user-manage')
router.register('assurances', PartnerAssuranceViewSet, basename='assurance-manage')
router.register('logs', AuditLogViewSet, basename='logs-manage')
router.register('notifications', NotificationViewSet, basename='notifications')

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('profile/', ProfileView.as_view(), name='profile'),
    path('change-password/', ChangePasswordView.as_view(), name='change-password'),
    path('stats/', StatisticsView.as_view(), name='admin-stats'),
    path('', include(router.urls)),
]
