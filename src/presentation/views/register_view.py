import flet as ft
# Imports ajustados para as novas cores
from common.colors import BACKGROUND_LIGHT, TEXT_LIGHT, TEXT_MUTED, PRIMARY
from presentation.components.action_button import ActionButton

class RegisterView(ft.View):
    def __init__(self, page: ft.Page, role: str, auth_service):
        super().__init__(
            route=f"/register/{role}",
            bgcolor=BACKGROUND_LIGHT, # Fundo claro
        )
        self.page = page
        self.role = role
        self.auth_service = auth_service
        
        title = "Paciente" if role == "patient" else "Cuidador"

        # Sua AppBar (Fundo branco, texto escuro)
        self.appbar = ft.AppBar(
            title=ft.Text(f"Cadastro de {title}", color=TEXT_LIGHT), # Texto escuro
            leading=ft.IconButton(
                icon=ft.Icons.ARROW_BACK,
                on_click=self.go_back_to_login,
                icon_color=TEXT_LIGHT # Ícone escuro
            ),
            bgcolor=ft.Colors.WHITE, # Fundo branco para a AppBar
            elevation=1 # Uma sombra leve para destacar
        )
        
        # Seus Campos de Texto (estilo M3 com "label")
        # Todos os campos com as novas cores de label e texto digitado
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

        # Link de Login
        login_link = ft.Row(
            [
                ft.Text("Já tem uma conta?", color=TEXT_MUTED),
                ft.TextButton(
                    "Entre", 
                    on_click=self.go_back_to_login,
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
                            f"Crie sua conta de {title}",
                            size=24, 
                            weight=ft.FontWeight.BOLD,
                            color=TEXT_LIGHT # Texto escuro
                        ),
                        
                        ft.AutofillGroup(
                            content=ft.Column(
                                [
                                    self.fullname_field,
                                    self.email_field,
                                    self.password_field,
                                    self.confirm_password_field,
                                ],
                                spacing=20 # Mais espaço entre os campos
                            )
                        ),
                        
                        ft.Container(height=20), # Espaçador maior
                        
                        self.continue_button, 
                        login_link,           
                    ],
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    spacing=30, # Mais espaço entre blocos
                    scroll=ft.ScrollMode.ADAPTIVE,
                ),
                padding=ft.padding.all(30), # Padding maior para a tela toda
                expand=True,
            )
        ]

    def handle_register(self, e):
        # 1. Validação de campos vazios
        if not all([self.fullname_field.value, self.email_field.value, 
                    self.password_field.value, self.confirm_password_field.value]):
            self.page.open(
                ft.SnackBar(
                    ft.Text("Por favor, preencha todos os campos.", color=ft.Colors.WHITE),
                    bgcolor=ft.Colors.RED_500,
                )
            )
            return
        
        # 2. Validação de senhas iguais
        if self.password_field.value != self.confirm_password_field.value:
            self.page.open(
                ft.SnackBar(
                    ft.Text("As senhas não coincidem.", color=ft.Colors.WHITE),
                    bgcolor=ft.Colors.RED_500,
                )
            )
            return

        # 3. Integração com Supabase
        try:
            # Trava o botão para evitar múltiplos cliques
            self.continue_button.content.disabled = True
            self.continue_button.update()
            
            print(f"Cadastrando {self.email_field.value} como {self.role}...")
            
            # Chama o serviço que criamos acima
            self.auth_service.register(
                name=self.fullname_field.value,
                email=self.email_field.value,
                password=self.password_field.value,
                role=self.role
            )
            
            # 4. Sucesso!
            self.page.open(
                ft.SnackBar(
                    content=ft.Text("Cadastro realizado com sucesso! Faça login.", color=ft.Colors.WHITE),
                    bgcolor=ft.Colors.GREEN_500
                )
            )
            
            # Redireciona para a tela de Login para a pessoa entrar
            self.page.go(f"/login/{self.role}")

        except Exception as error:
            # 5. Erro
            print(f"Erro ao registrar: {error}")
            self.page.open(
                ft.SnackBar(
                    content=ft.Text(str(error), color=ft.Colors.WHITE),
                    bgcolor=ft.Colors.RED_500,
                )
            )
        finally:
            # Destrava o botão (caso tenha dado erro)
            self.continue_button.content.disabled = False
            self.continue_button.update()
            
    def go_back_to_login(self, e):
        self.page.go(f"/login/{self.role}")