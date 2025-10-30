import flet as ft

class WelcomeView(ft.View):
    def __init__(self, page: ft.Page):
        super().__init__(route="/")
        self.page = page
        
        self.controls = [
            ft.Container(
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
                        ),
                        ft.ElevatedButton(
                            text="Começar",
                            on_click=self.go_to_select_role,
                        ),
                    ],
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    alignment=ft.MainAxisAlignment.CENTER,
                    spacing=20,
                ),
                alignment=ft.alignment.center,
                expand=True,
            )
        ]

    def go_to_select_role(self, e):
        print("Redirecionando - Tela de escolha de perfil")