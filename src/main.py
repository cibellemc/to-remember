import flet as ft
from presentation.views.welcome_view import WelcomeView

def main(page: ft.Page):
    page.title = "To Remember"
    page.views.append(WelcomeView(page))

    page.go("/")

ft.app(main)
