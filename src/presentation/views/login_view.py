import flet as ft

class LoginView(ft.View):
    def __init__(self, page: ft.Page, role: str, auth_service): # auth_service será injetado
        super().__init__(route=f"/login/{role}")
        self.page = page
        self.role = role
        self.auth_service = auth_service

        title = "Login do Paciente" if role == "patient" else "Login do Cuidador"

        self.email_field = ft.TextField(label="Email")
        self.password_field = ft.TextField(label="Senha", password=True)

        self.controls = [
            ft.Container(
                content=ft.Column(
                    [
                        ft.Text(value=title, size=24, weight=ft.FontWeight.BOLD),
                        self.email_field,
                        self.password_field,
                        ft.Container(
            content=ft.ElevatedButton(
                text="Entrar",
                on_click=self.handle_login,
                
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
        ),
                        ft.Container(
                            content=ft.ElevatedButton(
                                text="Não tenho uma conta. Cadastrar",
                                on_click=self.go_to_register,
                                
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
                    ],
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    alignment=ft.MainAxisAlignment.CENTER,
                    spacing=20,
                ),
                alignment=ft.alignment.center,
                padding=20,
                expand=True,
            )
        ]

    def handle_login(self, e):
        print("Simulando login...")
        
        self.page.views.clear()
        self.page.go(f"/dashboard/{self.role}")

    def go_to_register(self, e):
        self.page.go(f"/register/{self.role}")