import flet as ft

class RegisterView(ft.View):
    def __init__(self, page: ft.Page, role: str, auth_service):
        super().__init__(route=f"/register/{role}")
        self.page = page
        self.role = role
        self.auth_service = auth_service
        
        title = "Paciente" if role == "patient" else "Cuidador"

        self.appbar = ft.AppBar(
            title=ft.Text(f"Cadastro de {title}"),
            leading=ft.IconButton(
                icon=ft.Icons.ARROW_BACK,
                on_click=self.go_back_to_login,
            ),
            bgcolor=ft.Colors.ON_SURFACE_VARIANT,
        )
        
        self.fullname_field = ft.TextField(
            label="Nome Completo",
            autofill_hints=ft.AutofillHint.NAME,
        )
        
        self.email_field = ft.TextField(
            label="E-mail",
            autofill_hints=ft.AutofillHint.EMAIL,
        )
        
        self.password_field = ft.TextField(
            label="Senha",
            password=True,
            can_reveal_password=True,
            autofill_hints=ft.AutofillHint.NEW_PASSWORD,
        )
        
        self.confirm_password_field = ft.TextField(
            label="Confirmar Senha",
            password=True,
            can_reveal_password=True,
            autofill_hints=ft.AutofillHint.NEW_PASSWORD,
        )
        
        self.continue_button = ft.Container(
            content=ft.ElevatedButton(
                text="Continuar",
                on_click=self.handle_register,
                
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
            ft.Container(
                content=ft.Column(
                    [
                        ft.Text(
                            f"Crie sua conta de {title}",
                            size=24, 
                            weight=ft.FontWeight.BOLD
                        ),
                        
                        ft.AutofillGroup(
                            content=ft.Column(
                                [
                                    self.fullname_field,
                                    self.email_field,
                                    self.password_field,
                                    self.confirm_password_field,
                                ],
                                spacing=10 # Espaço pequeno entre os campos
                            )
                        ),
                        
                        ft.Container(height=10), # Espaçador
                        
                        self.continue_button,
                    ],
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    spacing=20, 
                ),
                padding=20, 
                expand=True,
            )
        ]


    def handle_register(self, e):
        # (Nenhuma mudança aqui)
        print("Simulando cadastro...")
        # Lógica de cadastro real viria aqui
        self.page.views.clear()
        self.page.go(f"/dashboard/{self.role}")

    def go_back_to_login(self, e):
        # (Nenhuma mudança aqui)
        self.page.go(f"/login/{self.role}")