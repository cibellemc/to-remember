import flet as ft
# Imports ajustados para as novas cores
from common.colors import BACKGROUND_LIGHT, TEXT_LIGHT, TEXT_MUTED, PRIMARY
from presentation.components.action_button import ActionButton

class LoginView(ft.View):
    def __init__(self, page: ft.Page, role: str, auth_service):
        super().__init__(
            route=f"/login/{role}",
            bgcolor=BACKGROUND_LIGHT, # Fundo claro
        )
        self.page = page
        self.role = role.capitalize()
        self.auth_service = auth_service 

        # --- AppBar Consistente (Fundo branco, texto escuro) ---
        self.appbar = ft.AppBar(
            title=ft.Text(f"Login de {self.role}", color=TEXT_LIGHT), # Texto escuro
            leading=ft.IconButton(
                icon=ft.Icons.ARROW_BACK,
                on_click=self.go_back_to_select_role,
                icon_color=TEXT_LIGHT # Ícone escuro
            ),
            bgcolor=ft.Colors.WHITE, # Fundo branco para a AppBar
            elevation=1 # Uma sombra leve para destacar
        )

        # --- Campos de Texto (estilo M3 com "label") ---
        self.email_field = ft.TextField(
            label="E-mail",
            keyboard_type=ft.KeyboardType.EMAIL,
            autofill_hints=ft.AutofillHint.USERNAME,
            label_style=ft.TextStyle(color=TEXT_MUTED), # Cor do label
            text_style=ft.TextStyle(color=TEXT_LIGHT), # Cor do texto digitado
            border_color=ft.Colors.GREY_300, # Borda em repouso
            focused_border_color=PRIMARY, # Borda focada
        )
        self.password_field = ft.TextField(
            label="Senha",
            password=True,
            can_reveal_password=True,
            autofill_hints=ft.AutofillHint.PASSWORD,
            label_style=ft.TextStyle(color=TEXT_MUTED),
            text_style=ft.TextStyle(color=TEXT_LIGHT),
            border_color=ft.Colors.GREY_300,
            focused_border_color=PRIMARY,
        )
        
        # Link "Esqueceu a senha"
        forgot_password_link = ft.TextButton(
            "Esqueceu sua senha?",
            on_click=self.forgot_password,
            style=ft.ButtonStyle(color=TEXT_MUTED) # Cor do texto do link
        )
        
        # Botão de Ação (padrão)
        login_button = ActionButton(
            text="Entrar",
            on_click=self.handle_login
        )
        login_button.padding = ft.padding.symmetric(horizontal=40)
        
        # Link de Cadastro
        signup_link = ft.Row(
            [
                ft.Text("Não tem uma conta?", color=TEXT_MUTED),
                ft.TextButton(
                    "Cadastre-se", 
                    on_click=self.go_to_register,
                    style=ft.ButtonStyle(color=PRIMARY) # Cor do link
                ),
            ],
            alignment=ft.MainAxisAlignment.CENTER,
        )
        
        # --- Layout Consistente (Coluna Única Rolável) ---
        self.controls = [
            ft.Container(
                content=ft.Column(
                    [
                        ft.Text(
                            f"Acesse sua conta de\n{self.role}",
                            size=24,
                            weight=ft.FontWeight.BOLD,
                            text_align=ft.TextAlign.CENTER,
                            color=TEXT_LIGHT, # Texto escuro
                        ),
                        ft.AutofillGroup(
                            content=ft.Column(
                                [
                                    self.email_field,
                                    self.password_field,
                                ],
                                spacing=20 # Mais espaço entre os campos
                            )
                        ),
                        ft.Row(
                            [forgot_password_link], 
                            alignment=ft.MainAxisAlignment.END
                        ),
                        ft.Container(height=20), # Espaçador maior
                        login_button,
                        signup_link,
                    ],
                    spacing=30, # Mais espaço entre blocos
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    scroll=ft.ScrollMode.ADAPTIVE,
                ),
                padding=ft.padding.all(30), # Padding maior para a tela toda
                expand=True,
            )
        ]

    def handle_login(self, e):
        email = self.email_field.value
        password = self.password_field.value
        if not email or not password:
            self.page.show_snack_bar(
                ft.SnackBar(
                    ft.Text("Por favor, preencha todos os campos.", color=ft.Colors.WHITE),
                    bgcolor=ft.Colors.RED_500,
                )
            )
            self.page.snack_bar.open = True
            self.page.update()
            return

        print(f"Login para {self.role} com E-mail: {email}")
        # self.auth_service.login(email, password, self.role)
        # self.page.go(f"/dashboard/{self.role.lower()}")

    def go_back_to_select_role(self, e):
        self.page.go("/select-role")

    def go_to_register(self, e):
        self.page.go(f"/register/{self.role.lower()}") 

    def forgot_password(self, e):
        print("Ir para 'Esqueci minha senha'")