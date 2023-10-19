from django.urls import path

from . import views

urlpatterns = [
    path("", views.index, name="index"),
    path("balance/<str:address>", views.balance, name="balance"),
]
