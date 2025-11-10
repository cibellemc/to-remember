# presentation/views/welcome_view.py
import flet as ft

class WelcomeView(ft.View):
    def __init__(self, page: ft.Page):
        super().__init__(route="/")
        self.page = page

        text_block = ft.Container(
            content=ft.Column(
                [
                    ft.Text(
                        value="Bem-vindo ao\nTo Remember",
                        size=32,
                        weight=ft.FontWeight.BOLD,
                        text_align=ft.TextAlign.CENTER,
                    ),
                    ft.Text(
                        value="Um aplicativo projetado para estimular a mente e acompanhar seu desempenho.",
                        size=16,
                        text_align=ft.TextAlign.CENTER,
                        width=300, # garantir quebra de linha mesmo nos dispositivos maiores
                    ),
                ],
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                alignment=ft.MainAxisAlignment.CENTER,
                spacing=30,
            ),
            alignment=ft.alignment.center,
            expand=True, 
        )

        start_button = ft.Container(
            content=ft.ElevatedButton(
                text="Começar",
                on_click=self.go_to_select_role,
                
                style=ft.ButtonStyle(
                    padding=ft.padding.symmetric(vertical=24, horizontal=32),
                    text_style=ft.TextStyle(
                        size=18, 
                        weight=ft.FontWeight.BOLD
                    ),
                    shape=ft.RoundedRectangleBorder(radius=10) 
                ),
                expand=True,
            ),
            padding=ft.padding.only(bottom=40, left=40, right=40), 
            alignment=ft.alignment.center,
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

    def go_to_select_role(self, e):
        print("Redirecionando - Tela de escolha de perfil")
        self.page.go("/select-role")