import flet as ft
from common.colors import BACKGROUND_LIGHT, TEXT_LIGHT, TEXT_MUTED, PRIMARY
from presentation.components.action_button import ActionButton

class RegisterView(ft.View):
    def __init__(self, page: ft.Page, role: str, auth_service):
        super().__init__(
            route=f"/register/{role}",
            bgcolor=BACKGROUND_LIGHT,
        )
        self.page = page
        self.role = role
        self.auth_service = auth_service
        
        # Limpa o "step2" do role se vier na URL
        display_role = role.replace("step2", "").strip()
        # Tradução simples para exibição
        title_text = "Paciente" if display_role == "patient" else "Cuidador"

        # AppBar
        self.appbar = ft.AppBar(
            title=ft.Column([
                ft.Text(f"Cadastro de {title_text}", color=TEXT_LIGHT, size=18, weight=ft.FontWeight.BOLD),
                ft.Text("Passo 2 de 3", color=TEXT_MUTED, size=12),
            ], spacing=0, alignment=ft.MainAxisAlignment.CENTER),
            center_title=True,
            leading=ft.IconButton(
                icon=ft.Icons.ARROW_BACK,
                on_click=self.go_back_to_step_1, # <--- CORREÇÃO AQUI
                icon_color=TEXT_LIGHT
            ),
            bgcolor=ft.Colors.WHITE,
            elevation=0
        )
        
        # Campos
        self.fullname_field = ft.TextField(
            label="Nome Completo",
            autofill_hints=ft.AutofillHint.NAME,
            label_style=ft.TextStyle(color=TEXT_MUTED),
            text_style=ft.TextStyle(color=TEXT_LIGHT),
            border_color=ft.Colors.GREY_300,
            focused_border_color=PRIMARY,
        )
        self.email_field = ft.TextField(
            label="E-mail",
            autofill_hints=ft.AutofillHint.EMAIL,
            label_style=ft.TextStyle(color=TEXT_MUTED),
            text_style=ft.TextStyle(color=TEXT_LIGHT),
            border_color=ft.Colors.GREY_300,
            focused_border_color=PRIMARY,
        )
        self.password_field = ft.TextField(
            label="Senha",
            password=True,
            can_reveal_password=True,
            autofill_hints=ft.AutofillHint.NEW_PASSWORD,
            label_style=ft.TextStyle(color=TEXT_MUTED),
            text_style=ft.TextStyle(color=TEXT_LIGHT),
            border_color=ft.Colors.GREY_300,
            focused_border_color=PRIMARY,
        )
        self.confirm_password_field = ft.TextField(
            label="Confirmar Senha",
            password=True,
            can_reveal_password=True,
            autofill_hints=ft.AutofillHint.NEW_PASSWORD,
            label_style=ft.TextStyle(color=TEXT_MUTED),
            text_style=ft.TextStyle(color=TEXT_LIGHT),
            border_color=ft.Colors.GREY_300,
            focused_border_color=PRIMARY,
        )
        
        self.continue_button = ActionButton(
            text="Continuar",
            on_click=self.handle_register
        )
        self.continue_button.padding = ft.padding.symmetric(horizontal=40)

        # Link Login (Caso a pessoa desista e já tenha conta)
        login_link = ft.Row(
            [
                ft.Text("Já tem uma conta?", color=TEXT_MUTED),
                ft.TextButton(
                    "Entre", 
                    on_click=self.go_to_login,
                    style=ft.ButtonStyle(color=PRIMARY)
                ),
            ],
            alignment=ft.MainAxisAlignment.CENTER,
        )

        # Layout
        self.controls = [
            ft.Container(
                content=ft.Column(
                    [
                        ft.Text("Crie sua conta", size=24, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT),
                        ft.AutofillGroup(
                            content=ft.Column(
                                [
                                    self.fullname_field,
                                    self.email_field,
                                    self.password_field,
                                    self.confirm_password_field,
                                ],
                                spacing=20
                            )
                        ),
                        ft.Container(height=20),
                        self.continue_button, 
                        login_link,           
                    ],
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    spacing=30,
                    scroll=ft.ScrollMode.ADAPTIVE,
                ),
                padding=ft.padding.all(30),
                expand=True,
            )
        ]

    def handle_register(self, e):
        # Validação de campos vazios
        if not all([self.fullname_field.value, self.email_field.value, 
                    self.password_field.value, self.confirm_password_field.value]):
            self.page.open(
                ft.SnackBar(
                    ft.Text("Por favor, preencha todos os campos.", color=ft.Colors.WHITE),
                    bgcolor=ft.Colors.RED_500,
                )
            )
            return
        
        # Validação de senhas
        if self.password_field.value != self.confirm_password_field.value:
            self.page.open(
                ft.SnackBar(
                    ft.Text("As senhas não coincidem.", color=ft.Colors.WHITE),
                    bgcolor=ft.Colors.RED_500,
                )
            )
            return
        
        # Prepara os dados
        basic_data = {
            "name": self.fullname_field.value,
            "email": self.email_field.value,
            "password": self.password_field.value
        }

        # Salva na sessão
        self.page.session.set("temp_register_data", basic_data)
        
        # Navega para o passo 3
        clean_role = self.role.replace("step2", "").strip()
        self.page.go(f"/register/step3/{clean_role}")

    def go_back_to_step_1(self, e):
        # Volta para a Seleção de Perfil (Passo 1)
        self.page.go("/select-role")

    def go_to_login(self, e):
        # Vai para a tela de Login (Cancelando o fluxo)
        self.page.go("/login")