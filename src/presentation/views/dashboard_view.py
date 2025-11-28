import flet as ft
from common.colors import BACKGROUND_LIGHT, TEXT_LIGHT, PRIMARY

class DashboardView(ft.View):
    def __init__(self, page: ft.Page, role: str):
        super().__init__(route=f"/dashboard/{role}", bgcolor=BACKGROUND_LIGHT)
        self.page = page
        self.role = role
        
        # Tradução para exibição
        role_display = "Paciente" if role == "patient" else "Cuidador"

        self.appbar = ft.AppBar(
            title=ft.Text(f"Dashboard do {role_display}", color=TEXT_LIGHT),
            bgcolor=ft.Colors.WHITE,
            elevation=0,
            center_title=True,
            actions=[
                ft.IconButton(ft.Icons.LOGOUT, icon_color=PRIMARY, on_click=self.logout)
            ]
        )

        self.controls = [
            ft.Container(
                content=ft.Column(
                    [
                        ft.Icon(ft.Icons.DASHBOARD, size=80, color=PRIMARY),
                        ft.Text(f"Bem-vindo, {role_display}!", size=24, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT),
                        ft.Text("Esta é a sua tela inicial.", color=ft.Colors.GREY_600),
                    ],
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    alignment=ft.MainAxisAlignment.CENTER,
                ),
                alignment=ft.alignment.center,
                expand=True
            )
        ]

    def logout(self, e):
        # Lógica de logout simples
        self.page.go("/login")