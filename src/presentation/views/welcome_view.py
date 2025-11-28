import flet as ft
from common.colors import BACKGROUND_LIGHT, TEXT_LIGHT, TEXT_SUBTLE
from presentation.components.action_button import ActionButton

class WelcomeView(ft.View):
    def __init__(self, page: ft.Page):
        super().__init__(
            route="/welcome", # Rota explícita
            bgcolor=BACKGROUND_LIGHT,
        )
        self.page = page

        # --- Bloco de Texto ---
        text_block = ft.Container(
            content=ft.Column(
                [
                    ft.Text(
                        value="Bem-vindo ao\nTo Remember",
                        size=32,
                        weight=ft.FontWeight.BOLD,
                        text_align=ft.TextAlign.CENTER,
                        color=TEXT_LIGHT,
                    ),
                    ft.Text(
                        value="Um aplicativo projetado para estimular a mente e acompanhar seu desempenho.",
                        size=16,
                        text_align=ft.TextAlign.CENTER,
                        color=TEXT_SUBTLE,
                    ),
                ],
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                alignment=ft.MainAxisAlignment.CENTER,
                spacing=30,
            ),
            alignment=ft.alignment.center,
            expand=True, 
            padding=ft.padding.symmetric(horizontal=40), 
        )

        # --- Botão Começar ---
        start_button = ActionButton(
            text="Começar",
            on_click=self.finish_welcome
        )

        self.controls = [
            ft.Column(
                [
                    text_block,  
                    start_button 
                ],
                expand=True,
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            )
        ]

    def finish_welcome(self, e):
        # 1. Marca no armazenamento local que o usuário já viu a intro
        self.page.client_storage.set("welcome_seen", True)
        
        # 2. Vai para a tela de Login
        print("Intro finalizada. Indo para Login.")
        self.page.go("/login")