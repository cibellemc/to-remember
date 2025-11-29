import flet as ft
from common.colors import BACKGROUND_LIGHT, TEXT_LIGHT, TEXT_MUTED, PRIMARY
from presentation.components.action_button import ActionButton

class LoginView(ft.View):
    def __init__(self, page: ft.Page, auth_service):
        super().__init__(
            route="/login", # Rota genérica agora
            bgcolor=BACKGROUND_LIGHT,
        )
        self.page = page
        self.auth_service = auth_service 

        # AppBar simples
        self.appbar = ft.AppBar(
            title=ft.Text("Login", color=TEXT_LIGHT),
            bgcolor=ft.Colors.WHITE,
            elevation=0,
            center_title=True,
            automatically_imply_leading=False # Sem seta de voltar na tela inicial
        )

        self.email_field = ft.TextField(
            label="E-mail",
            keyboard_type=ft.KeyboardType.EMAIL,
            label_style=ft.TextStyle(color=TEXT_MUTED),
            border_color=ft.Colors.GREY_300,
            focused_border_color=PRIMARY,
            text_style=ft.TextStyle(color=TEXT_LIGHT),
        )
        self.password_field = ft.TextField(
            label="Senha",
            password=True,
            can_reveal_password=True,
            label_style=ft.TextStyle(color=TEXT_MUTED),
            border_color=ft.Colors.GREY_300,
            focused_border_color=PRIMARY,
            text_style=ft.TextStyle(color=TEXT_LIGHT),
        )
        
        login_button = ActionButton(
            text="Entrar",
            on_click=self.handle_login
        )
        login_button.padding = ft.padding.symmetric(horizontal=40)
        
        # O botão de cadastro agora leva para a seleção de perfil
        signup_link = ft.Row(
            [
                ft.Text("Não tem uma conta?", color=TEXT_MUTED),
                ft.TextButton(
                    "Cadastre-se", 
                    on_click=self.go_to_select_role,
                    style=ft.ButtonStyle(color=PRIMARY)
                ),
            ],
            alignment=ft.MainAxisAlignment.CENTER,
        )
        
        self.controls = [
            ft.Container(
                content=ft.Column(
                    [
                        ft.Image(src="assets/icon.png", width=100, height=100) if False else ft.Icon(ft.Icons.LOCK_PERSON, size=80, color=PRIMARY), # Placeholder logo
                        ft.Text(
                            "Bem-vindo de volta",
                            size=24,
                            weight=ft.FontWeight.BOLD,
                            color=TEXT_LIGHT,
                        ),
                        ft.Container(height=20),
                        self.email_field,
                        self.password_field,
                        ft.Container(height=20),
                        login_button,
                        signup_link,
                    ],
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    spacing=20,
                    scroll=ft.ScrollMode.ADAPTIVE,
                ),
                padding=ft.padding.all(30),
                expand=True,
                alignment=ft.alignment.center
            )
        ]

    def handle_login(self, e):
        email = self.email_field.value
        password = self.password_field.value
        
        if not email or not password:
            self.page.open(ft.SnackBar(ft.Text("Preencha todos os campos"), bgcolor=ft.Colors.RED))
 
            return

        try:
            self.page.open(ft.SnackBar(ft.Text("Entrando..."), bgcolor=ft.Colors.BLUE))
            session = self.auth_service.login(email, password)
            
            # --- CORREÇÃO: Captura dados para passar para a próxima tela ---
            # 1. Pega o role
            user_role = session.user.user_metadata.get('role', 'patient') 
            
            # 2. Pega o nome completo (se existir no metadata)
            user_name = session.user.user_metadata.get('full_name', '')
            
            # 3. Salva na sessão do app para persistência simples (ou passar via rota)
            self.page.session.set("user_name", user_name)
            
            # 4. Vai para o dashboard
            self.page.go(f"/dashboard/{user_role}")

        except Exception as error:
            self.page.open(ft.SnackBar(ft.Text(str(error)), bgcolor=ft.Colors.RED))

    def go_to_select_role(self, e):
        # Inicia o fluxo de cadastro
        self.page.go("/select-role")